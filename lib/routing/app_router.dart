import 'package:flutter/material.dart';

import '../features/admin/admin_dashboard_screen.dart';
import '../features/bar/bar_dashboard_screen.dart';
import '../features/kitchen/kitchen_dashboard_screen.dart';
import '../features/login/login_screen.dart';
import '../features/manager/manager_dashboard_screen.dart';
import '../features/owner/owner_dashboard_screen.dart';
import '../features/supervisor/supervisor_dashboard_screen.dart';
import '../features/waiter/dashboard/waiter_dashboard_screen.dart';
import '../features/delivery/customer_delivery_screen.dart';
import '../features/delivery/rider_delivery_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String waiter = '/waiter';
  static const String kitchen = '/kitchen';
  static const String bar = '/bar';
  static const String admin = '/admin';
  static const String manager = '/manager';
  static const String supervisor = '/supervisor';
  static const String owner = '/owner';
  static const String customerDelivery = '/delivery';
  static const String riderDelivery = '/rider-delivery';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case login:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: login),
          builder: (_) => const LoginScreen(),
        );
      case waiter:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const WaiterDashboardScreen(),
        );
      case kitchen:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const KitchenDashboardScreen(),
        );
      case bar:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const BarDashboardScreen(),
        );
      case admin:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminDashboardScreen(),
        );
      case manager:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ManagerDashboardScreen(),
        );
      case supervisor:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SupervisorDashboardScreen(),
        );
      case owner:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const OwnerDashboardScreen(),
        );
      case customerDelivery:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const CustomerDeliveryScreen(),
        );
      case riderDelivery:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RiderDeliveryScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: login),
          builder: (_) => const LoginScreen(),
        );
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: login),
      builder: (_) => const LoginScreen(),
    );
  }
}
