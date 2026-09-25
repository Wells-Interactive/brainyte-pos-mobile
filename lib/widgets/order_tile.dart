import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../core/models/menu_item.dart';
import '../core/utils/currency.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({
    super.key,
    required this.item,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final MenuItem item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(CurrencyFormatter.format(item.price), style: TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove_circle_outline)),
              Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(onPressed: onIncrement, icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.format(lineTotal), style: const TextStyle(fontWeight: FontWeight.w800)),
              TextButton.icon(onPressed: onRemove, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}
