import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pistisai/config/app_config.dart';
import 'package:pistisai/services/hermes/hermes_streaming_service.dart';
import 'package:pistisai/services/onboarding/mobile_connection_service.dart';
import 'package:pistisai/services/settings_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('normalizeHubHost', () {
    test('accepts a Tailscale CGNAT address', () {
      expect(
        MobileConnectionService.normalizeHubHost('100.64.1.20'),
        '100.64.1.20',
      );
    });

    test('strips scheme, port, and path from a full URL', () {
      expect(
        MobileConnectionService.normalizeHubHost(
          'http://pc.tailnet.ts.net:8642/health',
        ),
        'pc.tailnet.ts.net',
      );
    });

    test('rejects blank input', () {
      expect(MobileConnectionService.normalizeHubHost('   '), isNull);
    });
  });

  group('MobileConnectionService', () {
    test('shows the connection screen until a mode is saved', () async {
      final service = MobileConnectionService();
      expect(await service.shouldShowConnectionScreen(), isTrue);
    });

    test('connectViaPistisaiApp persists cloud mode and hides the screen',
        () async {
      final service = MobileConnectionService();
      await service.connectViaPistisaiApp();

      expect(service.mode, MobileConnectionMode.pistisaiApp);
      expect(service.requireCloudLogin, isTrue);
      expect(await service.shouldShowConnectionScreen(), isFalse);
    });

    test('connectViaTailscaleHub saves Hermes URL when the desktop hub answers',
        () async {
      final hermes = HermesStreamingService();
      final settings = SettingsPreferenceService();
      final service = MobileConnectionService(
        settings: settings,
        hermesStreamingService: hermes,
        httpGet: (uri) async {
          if (uri.path == AppConfig.hubPath) {
            return http.Response('{"role":"primary_hub"}', 200);
          }
          return http.Response('nope', 404);
        },
      );

      final result = await service.connectViaTailscaleHub('100.64.1.20');

      expect(result.success, isTrue);
      expect(result.foundPrimaryHub, isTrue);
      expect(result.hermesUrl, 'http://100.64.1.20:8642');
      expect(hermes.baseUrl, 'http://100.64.1.20:8642');
      expect(await settings.getHermesUrl(), 'http://100.64.1.20:8642');
      expect(service.mode, MobileConnectionMode.tailscaleHub);
      expect(await service.shouldShowConnectionScreen(), isFalse);
      hermes.dispose();
    });

    test('falls back to Hermes /health when the hub path is absent', () async {
      final service = MobileConnectionService(
        httpGet: (uri) async {
          if (uri.path == '/health') {
            return http.Response('OK', 200);
          }
          throw Exception('hub down');
        },
      );

      final result = await service.probeHub('desktop');
      expect(result.success, isTrue);
      expect(result.foundPrimaryHub, isFalse);
      expect(result.hermesUrl, 'http://desktop:8642');
    });
  });
}
