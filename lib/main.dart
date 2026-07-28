import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/colors.dart';
import 'firebase_options.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_trips_screen.dart';
import 'screens/personal_info_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/publish_trip_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/search_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/trip_history_screen.dart';
import 'screens/trip_requests_screen.dart';
import 'screens/two_factor_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  AppColors.setDark(isDark);
  themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  runApp(CovoiturageESMTApp());
}

Page<void> _iosPage(Widget child) {
  return CupertinoPage(child: child);
}

class CovoiturageESMTApp extends StatelessWidget {
  CovoiturageESMTApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _iosPage(const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _iosPage(const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _iosPage(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => _iosPage(const ResetPasswordScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _iosPage(const HomeScreen()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _iosPage(const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _iosPage(const SearchScreen()),
      ),
      GoRoute(
        path: '/booking',
        pageBuilder: (context, state) {
          final trip = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return _iosPage(BookingScreen(trip: trip));
        },
      ),
      GoRoute(
        path: '/tracking',
        pageBuilder: (context, state) {
          String? tripId;
          String? reservationId;
          final extra = state.extra;
          if (extra is Map) {
            tripId = extra['tripId']?.toString();
            reservationId = extra['reservationId']?.toString();
          } else if (extra is String) {
            tripId = extra;
          }
          return _iosPage(
            TrackingScreen(tripId: tripId, reservationId: reservationId),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _iosPage(const ProfileScreen()),
      ),
      GoRoute(
        path: '/publish',
        pageBuilder: (context, state) => _iosPage(const PublishTripScreen()),
      ),
      GoRoute(
        path: '/verify-2fa',
        pageBuilder: (context, state) {
          final email = state.extra is String ? state.extra as String : '';
          return _iosPage(TwoFactorScreen(email: email));
        },
      ),
      GoRoute(
        path: '/add-vehicle',
        pageBuilder: (context, state) => _iosPage(const AddVehicleScreen()),
      ),
      GoRoute(
        path: '/personal-info',
        pageBuilder: (context, state) => _iosPage(const PersonalInfoScreen()),
      ),
      GoRoute(
        path: '/trip-history',
        pageBuilder: (context, state) => _iosPage(const TripHistoryScreen()),
      ),
      GoRoute(
        path: '/trip-requests',
        pageBuilder: (context, state) => _iosPage(const TripRequestsScreen()),
      ),
      GoRoute(
        path: '/my-trips',
        pageBuilder: (context, state) => _iosPage(const MyTripsScreen()),
      ),
    ],
  );

  ThemeData _buildTheme() {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final brightness = AppColors.isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.background,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      colorScheme:
          (AppColors.isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.statusRed,
        outline: AppColors.border,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.onColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.statusRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.statusRed, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        AppColors.setDark(mode == ThemeMode.dark);
        return MaterialApp.router(
          title: 'CovoiturageESMT',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          themeMode: ThemeMode.light,
          routerConfig: _router,
        );
      },
    );
  }
}