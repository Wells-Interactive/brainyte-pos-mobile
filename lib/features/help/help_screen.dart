import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How do I place an order?',
      'answer': 'Select a table, browse the menu, add items to your cart, and tap "Confirm Order".',
    },
    {
      'question': 'How do I pay for delivery?',
      'answer': 'Choose Paystack as your payment method during checkout and complete the payment online.',
    },
    {
      'question': 'How do I reset my password?',
      'answer': 'Tap "Forgot password?" on the login screen and follow the instructions sent to your email.',
    },
    {
      'question': 'How do I contact support?',
      'answer': 'Use the "Contact Us" option in the menu or email brainytellc@gmail.com.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    faq['answer']!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
