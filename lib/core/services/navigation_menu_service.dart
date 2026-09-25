import 'package:flutter/material.dart';

import '../../routing/app_router.dart';

/// Navigation menu item model.
class NavigationMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<String> allowedRoles;

  const NavigationMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.allowedRoles,
  });

  bool isAllowedForRole(String role) => allowedRoles.contains(role);

  String resolveRoute(String role) {
    if (route == '__HOME__') {
      return NavigationMenuService().getHomeRoute(role);
    }
    if (title == 'Billing' && role == NavigationMenuService.roleCustomer) {
      return '/customer-billing';
    }
    return route;
  }
}

/// Navigation menu service providing role-based menu items.
class NavigationMenuService {
  static final NavigationMenuService _instance = NavigationMenuService._internal();
  factory NavigationMenuService() => _instance;
  NavigationMenuService._internal();

  // Available roles
  static const String roleAdmin = 'admin';
  static const String roleOwner = 'owner';
  static const String roleManager = 'manager';
  static const String roleSupervisor = 'supervisor';
  static const String roleWaiter = 'waiter';
  static const String roleKitchen = 'kitchen';
  static const String roleBar = 'bar';
  static const String roleCustomer = 'customer';
  static const String roleRider = 'rider';

  /// Get all menu items available for a given role.
  List<NavigationMenuItem> getMenuItemsForRole(String role) {
    final allItems = _getAllMenuItems();
    return allItems.where((item) => item.isAllowedForRole(role)).toList();
  }

  /// Resolve the home/dashboard route for a specific role.
  String getHomeRoute(String role) {
    switch (role) {
      case roleAdmin:
        return AppRouter.admin;
      case roleOwner:
        return AppRouter.owner;
      case roleManager:
        return AppRouter.manager;
      case roleSupervisor:
        return AppRouter.supervisor;
      case roleWaiter:
        return AppRouter.waiter;
      case roleKitchen:
        return AppRouter.kitchen;
      case roleBar:
        return AppRouter.bar;
      case roleCustomer:
        return AppRouter.customerDelivery;
      case roleRider:
        return AppRouter.riderDelivery;
      default:
        return AppRouter.login;
    }
  }

  /// Get all available menu items.
  List<NavigationMenuItem> _getAllMenuItems() {
    return [
      NavigationMenuItem(
        title: 'Home',
        icon: Icons.home,
        route: '__HOME__',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer, roleRider],
      ),
      NavigationMenuItem(
        title: 'Settings',
        icon: Icons.settings,
        route: AppRouter.settings,
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleCustomer, roleRider],
      ),
      NavigationMenuItem(
        title: 'Miscellaneous Orders',
        icon: Icons.merge_type_outlined,
        route: AppRouter.miscellaneousOrders,
        allowedRoles: [roleWaiter],
      ),
      NavigationMenuItem(
        title: 'Customers',
        icon: Icons.people_outline,
        route: AppRouter.customerManagement,
        allowedRoles: [roleAdmin, roleOwner],
      ),
      NavigationMenuItem(
        title: 'Delivery',
        icon: Icons.delivery_dining,
        route: AppRouter.customerDelivery,
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleCustomer],
      ),
      NavigationMenuItem(
        title: 'Feedback',
        icon: Icons.feedback_outlined,
        route: AppRouter.feedback,
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer, roleRider],
      ),
      NavigationMenuItem(
        title: 'Contact Us',
        icon: Icons.contact_mail,
        route: AppRouter.contact,
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer, roleRider],
      ),
      NavigationMenuItem(
        title: 'About Brainyte',
        icon: Icons.info,
        route: AppRouter.about,
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer, roleRider],
      ),
      NavigationMenuItem(
        title: 'Rate This App',
        icon: Icons.star_rate,
        route: AppRouter.rateApp,
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer, roleRider],
      ),
      NavigationMenuItem(
        title: 'Help',
        icon: Icons.help_outline,
        route: AppRouter.help,
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer, roleRider],
      ),
    ];
  }

  /// Get the appropriate dashboard route for a role.
  String getDashboardRoute(String role) {
    switch (role) {
      case roleAdmin:
        return '/admin';
      case roleOwner:
        return '/owner';
      case roleManager:
        return '/manager';
      case roleSupervisor:
        return '/supervisor';
      case roleWaiter:
        return '/waiter';
      case roleKitchen:
        return '/kitchen';
      case roleBar:
        return '/bar';
      case roleCustomer:
        return '/delivery';
      case roleRider:
        return '/rider-delivery';
      default:
        return '/login';
    }
  }
}