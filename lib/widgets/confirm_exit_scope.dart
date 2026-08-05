import 'package:flutter/material.dart';

/// Wraps a [child] so that the Android system back button shows a
/// confirmation dialog before exiting the app instead of popping to an
/// invalid "/" route.
///
/// Uses [PopScope] with `canPop: false` and intercepts the pop via
/// [PopScope.onPopInvokedWithResult]. When the user confirms, the app is
/// exited by popping the nearest root route.
class ConfirmExitScope extends StatelessWidget {
  const ConfirmExitScope({super.key, required this.child});

  final Widget child;

  Future<bool> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit app?'),
          content: const Text('Do you really want to exit the application?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
          // Exit the app by popping the root frame route.
          final navigator = Navigator.of(context);
          navigator.popUntil((route) => route.isFirst);
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
      },
      child: child,
    );
  }
}
