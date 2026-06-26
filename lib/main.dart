// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/ad_manager.dart';
import 'services/analytics_service.dart';
import 'services/app_check_service.dart';
import 'services/consent_service.dart';
import 'services/crashlytics_service.dart';
import 'services/performance_service.dart';
import 'services/remote_config_service.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'shared/models/saved_calc.dart';

import 'services/ad_free_manager.dart';
import 'services/ad_free_analytics_tracker.dart';
import 'services/notification_service.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

void main() async {
  // Step 1: WidgetsFlutterBinding.ensureInitialized()
  // Must be the very first call — required before any platform channel usage.
  WidgetsFlutterBinding.ensureInitialized();
  await AdFreeManager.init();

  // Initialize Hive storage for saved calculations
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(SavedCalcAdapter());
    await Hive.openBox<SavedCalc>('saved_calcs');
    await Hive.openBox<Map>('app_notifications');
  } catch (e) {
    debugPrint('Hive initialization failed: $e');
  }

  final container = ProviderContainer();
  AdFreeManager.container = container;
  NotificationService.container = container;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _AppInitializer(),
    ),
  );
}

// ── Initialization wrapper ────────────────────────────────────────────────────

/// Runs the 9-step initialization sequence asynchronously and shows
/// [SplashScreen] until all steps complete (or maintenance mode is detected).
///
/// Initialization order (strict — must not be reordered):
///   1.  WidgetsFlutterBinding.ensureInitialized()   ← done in main()
///   2.  Firebase.initializeApp()
///   3.  CrashlyticsService.init()
///   4.  RemoteConfigService.instance.init()
///         → if maintenanceMode == true: show MaintenancePage, halt.
///   5.  ConsentService.instance.init()
///   6.  AnalyticsService.instance.init()
///   7.  PerformanceService.instance.init()
///   8.  AppCheckService.init()
///   9.  AdManager.instance.initialize()
///  10.  Transition to MortgageGlobeApp via setState.
///
/// Any step that fails is caught, logged to Crashlytics, and skipped.
/// The only halt condition is maintenanceMode == true after step 4.
class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  // Initialization states
  bool _initialized = false;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    // ── Step 2: Firebase.initializeApp() ─────────────────────────────────
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await NotificationService.instance.init();
    } catch (e, s) {
      // Firebase/Notifications are foundational — log via debugPrint since Crashlytics
      // is not yet available at this point. Continue; later steps may
      // still partially succeed.
      debugPrint('Firebase/Notification initialization failed: $e\n$s');
    }

    // ── Step 3: CrashlyticsService.init() ────────────────────────────────
    // Sets FlutterError.onError and PlatformDispatcher.instance.onError
    // INSIDE CrashlyticsService.init(). Do NOT set those handlers here
    // or anywhere else in the project.
    try {
      await CrashlyticsService.init();
    } catch (e, s) {
      debugPrint('CrashlyticsService.init() failed: $e\n$s');
    }

    // ── Step 4: RemoteConfigService.instance.init() ───────────────────────
    try {
      await RemoteConfigService.instance.init();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'RemoteConfigService.init() threw unexpectedly',
      );
    }

    // Maintenance mode check — the ONLY condition that halts launch.
    // No further initialization steps run when maintenanceMode is true.
    if (RemoteConfigService.instance.maintenanceMode) {
      if (mounted) setState(() => _maintenanceMode = true);
      return;
    }

    // ── Step 5: ConsentService.instance.init() ────────────────────────────
    // Must be fully awaited. UMP consent form and iOS ATT dialog are
    // handled entirely inside ConsentService — do not show them here.
    try {
      await ConsentService.instance.init();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'ConsentService.init() threw unexpectedly',
      );
    }

    // ── Step 6: AnalyticsService.instance.init() ──────────────────────────
    try {
      await AnalyticsService.instance.init();
      await AdFreeAnalyticsTracker.init();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AnalyticsService/AdFreeAnalyticsTracker.init() threw unexpectedly',
      );
    }

    // ── Step 7: PerformanceService.init() ────────────────────────────────
    // init() is a static method — do NOT call via instance.
    try {
      await PerformanceService.init();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'PerformanceService.init() threw unexpectedly',
      );
    }

    // ── Step 8: AppCheckService.init() ────────────────────────────────────
    try {
      await AppCheckService.init();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AppCheckService.init() threw unexpectedly',
      );
    }

    // ── Step 9: AdManager.instance.initialize() ───────────────────────────
    try {
      await AdManager.instance.initialize();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AdManager.initialize() threw unexpectedly',
      );
    }

    // ── Step 10: Transition to the real app ───────────────────────────────
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Maintenance mode — halt here, show maintenance page.
    if (_maintenanceMode) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _MaintenancePage(),
      );
    }

    // Steps 2–9 in progress — show branded splash.
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    // Step 10 — initialization complete, hand off to the real app.
    // MortgageGlobeApp owns the GoRouter with:
    //   observers: [AnalyticsService.instance.analyticsObserver]
    // Do NOT construct FirebaseAnalyticsObserver here.
    return const MortgageGlobeApp();
  }
}

// ── Maintenance page ──────────────────────────────────────────────────────────

class _MaintenancePage extends StatelessWidget {
  const _MaintenancePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082A73),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 72,
                  color: Color(0xFFF4C430),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Under Maintenance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We\'re performing scheduled maintenance.\n'
                  'Please check back shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFC8D0E0),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4C430),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
