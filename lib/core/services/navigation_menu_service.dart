import 'package:flutter/material.dart';

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

  /// Get all menu items available for a given role.
  List<NavigationMenuItem> getMenuItemsForRole(String role) {
    final allItems = _getAllMenuItems();
    return allItems.where((item) => item.isAllowedForRole(role)).toList();
  }

  /// Get all available menu items (for admin/owner).
  List<NavigationMenuItem> _getAllMenuItems() {
    return [
      const NavigationMenuItem(
        title: 'Home',
        icon: Icons.home,
        route: '/home',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer],
      ),
      const NavigationMenuItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/dashboard',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar],
      ),
      const NavigationMenuItem(
        title: 'Orders',
        icon: Icons.receipt_long,
        route: '/orders',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar],
      ),
      const NavigationMenuItem(
        title: 'Menu',
        icon: Icons.restaurant_menu,
        route: '/menu',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer],
      ),
      const NavigationMenuItem(
        title: 'Billing',
        icon: Icons.payment,
        route: '/billing',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter],
      ),
      const NavigationMenuItem(
        title: 'Tables',
        icon: Icons.table_bar,
        route: '/tables',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter],
      ),
      const NavigationMenuItem(
        title: 'Inventory',
        icon: Icons.inventory_2,
        route: '/inventory',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor],
      ),
      const NavigationMenuItem(
        title: 'Reports',
        icon: Icons.analytics,
        route: '/reports',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor],
      ),
      const NavigationMenuItem(
        title: 'Settings',
        icon: Icons.settings,
        route: '/settings',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer],
      ),
      const NavigationMenuItem(
        title: 'Contact',
        icon: Icons.contact_mail,
        route: '/contact',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer],
      ),
      const NavigationMenuItem(
        title: 'About Brainyte',
        icon: Icons.info,
        route: '/about',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleKitchen, roleBar, roleCustomer],
      ),
      const NavigationMenuItem(
        title: 'Delivery',
        icon: Icons.delivery_dining,
        route: '/delivery',
        allowedRoles: [roleAdmin, roleOwner, roleManager, roleSupervisor, roleWaiter, roleCustomer],
      ),
    ];
  }

  /// Get the appropriate dashboard route for a role.
  String getDashboardRoute(String role) {
    switch (role) {
      case roleAdmin:
        return '/admin/dashboard';
      case roleOwner:
        return '/owner/dashboard';
      case roleManager:
        return '/manager/dashboard';
      case roleSupervisor:
        return '/supervisor/dashboard';
      case roleWaiter:
        return '/waiter/dashboard';
      case roleKitchen:
        return '/kitchen/dashboard';
      case roleBar:
        return '/bar/dashboard';
      case roleCustomer:
        return '/customer/dashboard';
      default:
        return '/login';
    }
  }
}