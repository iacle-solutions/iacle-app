import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pistisai/config/app_config.dart';
import 'package:pistisai/services/hermes/hermes_streaming_service.dart';
import 'package:pistisai/services/settings_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How this phone reaches the user's agent.
enum MobileConnectionMode {
  tailscaleHub,
  pistisaiApp,
}

class MobileHubProbeResult {
  const MobileHubProbeResult({
    required this.success,
    required this.hermesUrl,
    required this.message,
    this.foundPrimaryHub = false,
  });

  final bool success;
  final String hermesUrl;
  final String message;
  final bool foundPrimaryHub;
}

typedef MobileHubHttpGet = Future<http.Response> Function(Uri uri);

/// Mobile-only connection to the primary desktop hub or pistisai.app.
class MobileConnectionService extends ChangeNotifier {
  static const String modeKey = 'mobile_connection_mode';
  static const String completeKey = 'mobile_connection_complete';

  MobileConnectionService({
    SettingsPreferenceService? settings,
    HermesStreamingService? hermesStreamingService,
    MobileHubHttpGet? httpGet,
    this.hubPort = AppConfig.defaultRouterPort,
    this.hermesPort = AppConfig.defaultHermesPort,
  })  : _settings = settings ?? SettingsPreferenceService(),
        _hermesStreamingService = hermesStreamingService,
        _httpGet = httpGet;

  final SettingsPreferenceService _settings;
  final HermesStreamingService? _hermesStreamingService;
  final MobileHubHttpGet? _httpGet;
  final int hubPort;
  final int hermesPort;

  MobileConnectionMode? _mode;
  bool _complete = false;
  bool _loaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  MobileConnectionMode? get mode => _mode;
  bool get isComplete => _complete;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get requireCloudLogin => _mode == MobileConnectionMode.pistisaiApp;

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _mode = parseMode(prefs.getString(modeKey));
    _complete = prefs.getBool(completeKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<bool> shouldShowConnectionScreen() async {
    await load();
    return !_complete;
  }

  /// Accepts a Tailscale IP, MagicDNS name, or full HTTP URL.
  static String? normalizeHubHost(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.contains('://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null || uri.host.isEmpty) {
        return null;
      }
      return uri.host;
    }
    final withoutPath = trimmed.split('/').first;
    final host = withoutPath.split(':').first.trim();
    return host.isEmpty ? null : host;
  }

  Future<MobileHubProbeResult> probeHub(String rawHost) async {
    final host = normalizeHubHost(rawHost);
    if (host == null) {
      return const MobileHubProbeResult(
        success: false,
        hermesUrl: '',
        message: 'Enter the Tailscale address of your desktop hub.',
      );
    }

    final hermesUrl = 'http://$host:$hermesPort';
    final hubUri = Uri.parse('http://$host:$hubPort${AppConfig.hubPath}');
    try {
      final hubResponse = await _get(hubUri);
      if (hubResponse.statusCode == 200 && _isPrimaryHub(hubResponse.body)) {
        return MobileHubProbeResult(
          success: true,
          hermesUrl: hermesUrl,
          foundPrimaryHub: true,
          message: 'Connected to the primary desktop hub.',
        );
      }
    } catch (e) {
      debugPrint('[MobileConnection] Hub probe failed: $e');
    }

    final healthUri = Uri.parse('$hermesUrl/health');
    try {
      final health = await _get(healthUri);
      if (health.statusCode == 200) {
        return MobileHubProbeResult(
          success: true,
          hermesUrl: hermesUrl,
          message: 'Reached Hermes on the desktop through Tailscale.',
        );
      }
    } catch (e) {
      debugPrint('[MobileConnection] Hermes probe failed: $e');
    }

    return MobileHubProbeResult(
      success: false,
      hermesUrl: hermesUrl,
      message:
          'Could not reach a Pistisai desktop hub at $host. Open Tailscale on this phone, join the same tailnet as your PC, and use that PC\'s Tailscale name or 100.x address.',
    );
  }

  Future<MobileHubProbeResult> connectViaTailscaleHub(String rawHost) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await probeHub(rawHost);
      if (!result.success) {
        _errorMessage = result.message;
        return result;
      }
      await _settings.setHermesEnabled(true);
      await _settings.setHermesUrl(result.hermesUrl);
      _hermesStreamingService?.updateBaseUrl(result.hermesUrl);
      await _persist(
        mode: MobileConnectionMode.tailscaleHub,
        complete: true,
      );
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectViaPistisaiApp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _persist(
        mode: MobileConnectionMode.pistisaiApp,
        complete: true,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist({
    required MobileConnectionMode mode,
    required bool complete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(modeKey, encodeMode(mode));
    await prefs.setBool(completeKey, complete);
    _mode = mode;
    _complete = complete;
  }

  Future<http.Response> _get(Uri uri) {
    final get = _httpGet;
    if (get != null) {
      return get(uri);
    }
    return http.get(uri).timeout(const Duration(seconds: 5));
  }

  static bool _isPrimaryHub(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded['role'] == 'primary_hub';
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static MobileConnectionMode? parseMode(String? raw) {
    switch (raw) {
      case 'tailscale_hub':
        return MobileConnectionMode.tailscaleHub;
      case 'pistisai_app':
        return MobileConnectionMode.pistisaiApp;
      default:
        return null;
    }
  }

  static String encodeMode(MobileConnectionMode mode) {
    switch (mode) {
      case MobileConnectionMode.tailscaleHub:
        return 'tailscale_hub';
      case MobileConnectionMode.pistisaiApp:
        return 'pistisai_app';
    }
  }
}
