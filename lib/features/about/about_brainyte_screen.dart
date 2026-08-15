import 'package:flutter/material.dart';

/// About Brainyte screen displaying information about the company.
class AboutBrainyteScreen extends StatelessWidget {
  const AboutBrainyteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Brainyte'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo or App Icon
            Center(
              child: Icon(
                Icons.restaurant,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            Center(
              child: Text(
                'Brainyte Restaurant POS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Version
            Center(
              child: Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const Divider(height: 32),
            // About Text
            Text(
              'About Brainyte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Brainyte Restaurant POS is a comprehensive point-of-sale system designed for modern restaurants. '
              'Our platform streamlines operations by connecting waiters, kitchen staff, bar staff, managers, and customers '
              'through a unified digital experience.\n\n'
              'Features include real-time order management, table tracking, inventory control, '
              'detailed reporting, and mobile accessibility for both staff and customers.\n\n'
              'Built with performance and reliability in mind, Brainyte helps restaurants of all sizes '
              'deliver exceptional service while optimizing operational efficiency.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // Company Info
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              icon: Icons.email,
              label: 'Email',
              value: 'brainytellc@gmail.com',
            ),
            _buildInfoRow(
              context,
              icon: Icons.phone,
              label: 'Phone',
              value: '+234 806 7519 239',
            ),
            _buildInfoRow(
              context,
              icon: Icons.language,
              label: 'Website',
              value: 'www.wellsint.site/brainyte',
            ),
            const Spacer(),
            // Copyright
            Center(
              child: Text(
                '© ${DateTime.now().year} Brainyte. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}