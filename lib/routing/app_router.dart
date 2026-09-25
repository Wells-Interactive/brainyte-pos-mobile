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
import '../features/delivery/customer_registration_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/billing/billing_screen.dart';
import '../features/contact/contact_screen.dart';
import '../features/about/about_brainyte_screen.dart';
import '../features/password_reset/password_reset_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/rate_app/rate_this_app_screen.dart';
import '../features/help/help_screen.dart';
import '../features/billing/customer_billing_screen.dart';
import '../features/waiter/miscellaneous_orders_screen.dart';
import '../features/admin/customer_management_screen.dart';

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
  static const String settings = '/settings';
  static const String billing = '/billing';
  static const String customerBilling = '/customer-billing';
  static const String contact = '/contact';
  static const String about = '/about';
  static const String passwordReset = '/password-reset';
  static const String customerRegistration = '/customer-registration';
  static const String feedback = '/feedback';
  static const String rateApp = '/rate-app';
  static const String help = '/help';
  static const String miscellaneousOrders = '/miscellaneous-orders';
  static const String customerManagement = '/customer-management';

  /// Returns the dashboard route owned by a role.  Keeping this mapping here
  /// makes startup restoration use the same destinations as a fresh login.
  static String routeForRole(String role) {
    return switch (role.toLowerCase()) {
      'admin' => admin,
      'owner' => owner,
      'manager' => manager,
      'supervisor' => supervisor,
      'kitchen' => kitchen,
      'bar' => bar,
      'customer' => customerDelivery,
      'rider' => riderDelivery,
      _ => waiter,
    };
  }

  static Widget homeForRole(String role) {
    return switch (routeForRole(role)) {
      admin => const AdminDashboardScreen(),
      owner => const OwnerDashboardScreen(),
      manager => const ManagerDashboardScreen(),
      supervisor => const SupervisorDashboardScreen(),
      kitchen => const KitchenDashboardScreen(),
      bar => const BarDashboardScreen(),
      customerDelivery => const CustomerDeliveryScreen(),
      riderDelivery => const RiderDeliveryScreen(),
      _ => const WaiterDashboardScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case '/':
      case login:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: login),
          builder: (_) => const LoginScreen(),
        );
      case waiter:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const WaiterDashboardScreen(),
        );
      case kitchen:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const KitchenDashboardScreen(),
        );
      case bar:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const BarDashboardScreen(),
        );
      case admin:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const AdminDashboardScreen(),
        );
      case manager:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const ManagerDashboardScreen(),
        );
      case supervisor:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const SupervisorDashboardScreen(),
        );
      case owner:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const OwnerDashboardScreen(),
        );
      case customerDelivery:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const CustomerDeliveryScreen(),
        );
      case riderDelivery:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const RiderDeliveryScreen(),
        );
      case settings:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const SettingsScreen(),
        );
      case billing:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const BillingScreen(),
        );
      case customerBilling:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const CustomerBillingScreen(),
        );
      case contact:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const ContactScreen(),
        );
      case about:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const AboutBrainyteScreen(),
        );
      case passwordReset:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const PasswordResetScreen(),
        );
      case customerRegistration:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const CustomerRegistrationScreen(),
        );
      case feedback:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const FeedbackScreen(),
        );
      case rateApp:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const RateThisAppScreen(),
        );
      case help:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const HelpScreen(),
        );
      case miscellaneousOrders:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const MiscellaneousOrdersScreen(),
        );
      case customerManagement:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const CustomerManagementScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: login),
          builder: (_) => const LoginScreen(),
        );
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings routeSettings) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: login),
      builder: (_) => const LoginScreen(),
    );
  }
}
