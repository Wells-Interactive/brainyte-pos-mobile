import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/services/navigation_menu_service.dart';

class RoleBasedDrawer extends StatelessWidget {
  const RoleBasedDrawer({
    super.key,
    required this.role,
    required this.currentRoute,
  });

  final String role;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final menuService = NavigationMenuService();
    final menuItems = menuService.getMenuItemsForRole(role);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.person, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...menuItems.map((item) {
            final effectiveRoute = item.resolveRoute(role);
            final isSelected = currentRoute == effectiveRoute;
            return ListTile(
              leading: Icon(
                item.icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onTap: () {
                Navigator.pop(context);
                if (effectiveRoute != currentRoute) {
                  Navigator.of(context).pushReplacementNamed(effectiveRoute);
                }
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              ApiClient.instance.clearSession();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
