import 'package:flutter/material.dart';

import '../models/cash_flow.dart';
import '../models/transaction_type.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem({super.key, required this.expense});
  final CashFlow expense;

  Color _amountColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (expense.transactionType) {
      case TransactionType.income:
        return colorScheme.primary;
      case TransactionType.maaser:
        return colorScheme.tertiary;
      case TransactionType.deductions:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final amountColor = _amountColor(context);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurfaceVariant,
              child: Icon(transactionIcons[expense.transactionType]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${expense.formattedDate} • ${expense.hebrewDate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
