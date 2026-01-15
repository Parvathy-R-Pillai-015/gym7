import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/add_trainer_screen.dart';

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String adminDashboard = '/admin-dashboard';
  static const String addTrainer = '/add-trainer';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      landing: (context) => const LandingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) => const HomeScreen(),
      adminDashboard: (context) => const AdminDashboard(),
      addTrainer: (context) => const AddTrainerScreen(),
    };
  }
}
