# Launch Content Brief — superseded

> Current product description: [README](../../README.md) ([English](../../README.en.md)).
> How to run the code: [docs/LAUNCH.md](../LAUNCH.md).
> Repository: [github.com/iacle-solutions/iacle-app](https://github.com/iacle-solutions/iacle-app).

This brief no longer governs outward-facing copy. It described an earlier Pistisai
launch. `pistisai.app` returns Cloudflare error 1033, and issue #39 on
`pistisAI/pistisai-app` is a different project. Use the README.

The notes below are kept so old drafts can be compared. Do not publish them as-is.

## Product at a glance

- **What it is:** A local-first companion and desktop capability layer for your AI agent.
  Private, secure, yours.
- **What it is NOT:** A model, and not a hosted chatbot. It is the layer in front of an agent
  runtime (Hermes, OpenClaw, or any compatible agent gateway).
- **Core promise:** Voice, vision, and audited desktop control over your own private
  (Tailscale-first) mesh. No data leaves your network unless you decide otherwise.

## One-liner (canonical)

> **Pistisai turns your AI agent into a private desktop companion: voice, vision, and audited
> desktop control, connected over your own Tailscale mesh — local-first, no data leaves your
> network unless you say so.**

Use this verbatim across all channels. Variations for space-constrained surfaces (e.g. social
bio) live in `publish-ready/social-thread-pack.md`.

## Primary CTA

Use the README. Clone [iacle-solutions/iacle-app](https://github.com/iacle-solutions/iacle-app) and run it from source. Do not send people to `pistisai.app` until that host answers.

## Voice and tone

- Plain, confident, technical but not jargon-heavy.
- Lead with the user's control and privacy, not features for their own sake.
- No hype superlatives ("revolutionary", "world's first"). Show, don't claim.
- Acknowledge what's in development (Windows installer, macOS) honestly.

## Channels and owners

| Channel | Asset | Owner |
|---------|-------|-------|
| GitHub issue thread | issue #39 (this post) | Founder |
| Twitter/X thread | `publish-ready/social-thread-pack.md` | CMO |
| LinkedIn operator post | `publish-ready/social-thread-pack.md` | CMO |
| Discord announcement | `publish-ready/social-thread-pack.md` | DevRel |
| Community copy set | `publish-ready/community-copy-pack.md` | DevRel |
| Measurement plan | `publish-ready/measurement-plan.md` | DevRel |

## Messaging pillars (rotate across the week-1 plan)

1. **Install/try path** — it runs in a browser, zero install.
2. **Standards / CI gates** — branch protection, CodeQL, Dependabot, secret scanning.
3. **Offline / failover** — local-first means it keeps working without the cloud.
4. **Contributor onboarding** — how to wire your own agent runtime.
5. **Week summary + next preview** — recap and a teaser.

## Guardrails

- Link the README and [iacle-solutions/iacle-app](https://github.com/iacle-solutions/iacle-app). Do not send people to `pistisai.app` while it returns Cloudflare error 1033.
- Never claim a platform status that contradicts `docs/LAUNCH.md` or the README.
- Report security issues to `security@pistisai.app`, never in public threads.
- Keep copy in the repo so it is reviewable and version-controlled.
