import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _openEmail(BuildContext context, {required String to, required String subject}) async {
    final uri = Uri.parse('mailto:$to?subject=${Uri.encodeComponent(subject)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.contact_mail, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  'Contact Brainyte',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reach our support team directly.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openEmail(
                      context,
                      to: 'brainytellc@gmail.com',
                      subject: 'Brainyte POS Support',
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email Brainyte Support'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openEmail(
                      context,
                      to: 'brainytellc@gmail.com',
                      subject: 'Brainyte POS Feedback',
                    ),
                    icon: const Icon(Icons.feedback_outlined),
                    label: const Text('Send Feedback'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
