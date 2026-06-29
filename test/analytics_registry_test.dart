// ignore_for_file: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mortgagepro_global/app/router.dart';
import 'package:mortgagepro_global/services/analytics/analytics_screen.dart';

void main() {
  // Setup Firebase Mocks before loading appRouter/AnalyticsService
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();

    const MethodChannel analyticsChannel = MethodChannel('plugins.flutter.io/firebase_analytics');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(analyticsChannel, (MethodCall methodCall) async {
      return null;
    });

    await Firebase.initializeApp();
  });

  group('Analytics Route Registry Tests', () {
    test('Every static GoRouter route path exists as a key in the registry', () {
      final routes = appRouter.configuration.routes;
      final registryKeys = AnalyticsScreen.routeRegistry.keys.toSet();

      void verifyRoute(RouteBase route, String parentPath) {
        if (route is GoRoute) {
          final currentPath = parentPath == '/' 
              ? (route.path.startsWith('/') ? route.path : '/${route.path}')
              : (route.path.startsWith('/') ? route.path : '$parentPath/${route.path}');

          // Skip dynamic parameterized routes and wildcard fallbacks
          if (!currentPath.contains(':') && !currentPath.contains('*')) {
            expect(
              registryKeys.contains(currentPath),
              true,
              reason: 'GoRouter route "$currentPath" is missing from AnalyticsScreen.routeRegistry.',
            );

            final info = AnalyticsScreen.routeRegistry[currentPath]!;
            expect(info.screenName.isNotEmpty, true);
            expect(info.screenClass.isNotEmpty, true);
            expect(info.pageTitle.isNotEmpty, true);
          }

          for (final child in route.routes) {
            verifyRoute(child, currentPath);
          }
        }
      }

      for (final route in routes) {
        verifyRoute(route, '');
      }
    });

    test('No two static routes in the registry map to the same screen_name', () {
      final screenNamesSeen = <String, String>{}; // screenName -> path

      AnalyticsScreen.routeRegistry.forEach((path, info) {
        // Skip duplicate paths that map to the same screen (like '/' and '/home')
        if (path == '/' && AnalyticsScreen.routeRegistry.containsKey('/home')) {
          return;
        }

        final screenName = info.screenName;
        expect(
          screenNamesSeen.containsKey(screenName),
          false,
          reason: 'Duplicate screen_name "$screenName" found for both "$path" and "${screenNamesSeen[screenName]}". Each route must map to a unique screen_name.',
        );
        screenNamesSeen[screenName] = path;
      });
    });
  });
}
