import 'package:flutter/material.dart';

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
    return WillPopScope(
      onWillPop: () => _confirmExit(context),
      child: child,
    );
  }
}
