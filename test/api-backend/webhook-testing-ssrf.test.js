/**
 * Regression tests for the webhook-testing SSRF finding.
 *
 * An allowlisted host (webhook.site) can answer a 302 with an arbitrary
 * Location. Node fetch follows redirects by default, so the second request
 * is never re-checked against the allowlist and its body is echoed back.
 * These tests pin the redirect policy and the per-user cache scoping.
 */

import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals';
import { WebhookTestingService } from '../../services/api-backend/services/webhook-testing-service.js';

describe('Webhook testing SSRF hardening', () => {
  let service;
  const originalFetch = global.fetch;

  beforeEach(() => {
    service = new WebhookTestingService();
  });

  afterEach(() => {
    global.fetch = originalFetch;
    service.clearTestEventCache();
    jest.restoreAllMocks();
  });

  it('never lets fetch follow a redirect off the allowlisted host', async () => {
    const mockFetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      statusText: 'OK',
      headers: new Map([['content-type', 'text/plain']]),
      text: async () => 'OK',
      json: async () => ({}),
    });
    global.fetch = mockFetch;

    await service.simulateWebhookDelivery(
      'https://webhook.site/test',
      { id: '1' },
    );

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0][1]).toMatchObject({ redirect: 'error' });
  });

  it('does not return a body from a redirect target', async () => {
    // Faithful fake: an internal target is only fetched when the client
    // follows the 302. With redirect:'error' the client throws instead.
    const internalBody = 'SECRET-INTERNAL-METADATA';
    const internalUrl = 'http://169.254.169.254/latest/meta-data/';
    global.fetch = jest.fn().mockImplementation((url, options) => {
      let target = url;
      if (target === 'https://webhook.site/redirector') {
        if (options?.redirect === 'error') {
          return Promise.reject(new Error('redirect'));
        }
        // Node fetch follows the 302 internally: the next hop is the
        // attacker-chosen internal URL, and no allowlist check runs on it.
        target = internalUrl;
      }
      return Promise.resolve({
        ok: true,
        status: 200,
        statusText: 'OK',
        headers: new Map([['content-type', 'text/plain']]),
        text: async () => (target === internalUrl ? internalBody : 'OK'),
      });
    });

    const result = await service.simulateWebhookDelivery(
      'https://webhook.site/redirector',
      { id: '2' },
    );

    expect(result.success).toBe(false);
    expect(JSON.stringify(result)).not.toContain(internalBody);
  });

  it('scopes cached test events to the owning user', async () => {
    service.cacheTestEvent('event-alice', { success: true }, 'alice');
    service.cacheTestEvent('event-bob', { success: true }, 'bob');

    expect(service.getAllTestEvents(100, 'alice').length).toBe(1);
    expect(service.getAllTestEvents(100, 'bob').length).toBe(1);
    expect(service.getAllTestEvents(100, 'carol').length).toBe(0);
    expect(service.getTestEvent('event-alice', 'bob')).toBeNull();
    expect(service.getTestEvent('event-alice', 'alice')).not.toBeNull();
  });

  it('still serves legacy unowned cache entries to callers without a user', () => {
    service.cacheTestEvent('legacy', { success: true });
    expect(service.getTestEvent('legacy')).not.toBeNull();
    expect(service.getAllTestEvents().length).toBe(1);
  });
});
