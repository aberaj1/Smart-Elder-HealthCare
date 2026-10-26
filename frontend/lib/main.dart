import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/elder_dashboard_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/medicine_reminder_screen.dart';

import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // TIMEZONE
  // ============================================================

  tz.initializeTimeZones();

  tz.setLocalLocation(
    tz.getLocation('Asia/Kolkata'),
  );

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // NOTIFICATION
  // ============================================================

  await NotificationService.instance
      .initialize();

  runApp(
    const MyApp(),
  );
}

// ================================================================
// MY APP
// ================================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Notification app running state
    NotificationService.instance
        .medicineReminderTapNotifier
        .addListener(
      _onMedicineNotificationTapped,
    );

    // App closed state
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        _checkPendingNotification();
      },
    );
  }

  @override
  void dispose() {
    NotificationService.instance
        .medicineReminderTapNotifier
        .removeListener(
      _onMedicineNotificationTapped,
    );

    super.dispose();
  }

  // ============================================================
  // NOTIFICATION TAP LISTENER
  // ============================================================

  void _onMedicineNotificationTapped() {
    final reminderId =
        NotificationService.instance
            .medicineReminderTapNotifier
            .value;

    if (reminderId == null ||
        reminderId.isEmpty) {
      return;
    }

    _openMedicineReminder();
  }

  // ============================================================
  // CHECK NOTIFICATION WHEN APP IS CLOSED
  // ============================================================

  void _checkPendingNotification() {
    Future.delayed(
      const Duration(
        milliseconds: 1200,
      ),
      () {
        _openMedicineReminder();
      },
    );
  }

  // ============================================================
  // OPEN MEDICINE REMINDER
  // ============================================================

  void _openMedicineReminder() {
    final navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
        () {
          _openMedicineReminder();
        },
      );

      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final reminderId =
        NotificationService.instance
            .pendingMedicineReminderId;

    if (reminderId == null ||
        reminderId.isEmpty) {
      return;
    }

    // Clear notification data
    NotificationService.instance
        .pendingMedicineReminderId = null;

    NotificationService.instance
        .medicineReminderTapNotifier
        .value = null;

    navigator.push(
      MaterialPageRoute(
        builder: (context) =>
            MedicineReminderScreen(
          initialReminderId:
              reminderId,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      navigatorKey:
          navigatorKey,

      debugShowCheckedModeBanner:
          false,

      title:
          'Smart Elder Healthcare',

      theme:
          ThemeData(
        primarySwatch:
            Colors.blue,

        useMaterial3:
            true,
      ),

      home:
          const AuthChecker(),
    );
  }
}

// ================================================================
// AUTH CHECKER
// ================================================================

class AuthChecker extends StatelessWidget {
  const AuthChecker({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance
              .authStateChanges(),

      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData &&
            snapshot.data != null) {
          return const RoleChecker();
        }

        return const LoginScreen();
      },
    );
  }
}

// ================================================================
// ROLE CHECKER
// ================================================================

class RoleChecker
    extends StatelessWidget {
  const RoleChecker({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),

      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to load user profile.',
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const RoleSelectionScreen();
        }

        final data =
            snapshot.data!.data();

        final role =
            data?['role']
                ?.toString()
                .toLowerCase();

        // ========================================================
        // ELDER
        // ========================================================

        if (role == 'elder') {
          return const ElderDashboardScreen();
        }

        // ========================================================
        // CAREGIVER / CARETAKER
        // ========================================================

        if (role == 'caregiver' ||
            role == 'caretaker') {
          return const CaregiverDashboardScreen();
        }

        // ========================================================
        // NO ROLE
        // ========================================================

        return const RoleSelectionScreen();
      },
    );
  }
}