import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cash_flow.dart';
import '../models/transaction_type.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem({super.key, required this.expense});
  final CashFlow expense;

  Color _typeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (expense.transactionType) {
      case TransactionType.income:
        return colorScheme.primary;
      case TransactionType.deductions:
        return colorScheme.secondary;
      case TransactionType.maaser:
        return colorScheme.tertiary;
    }
  }

  IconData _typeIcon() {
    switch (expense.transactionType) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.deductions:
        return Icons.remove_circle_outline;
      case TransactionType.maaser:
        return Icons.volunteer_activism_rounded;
    }
  }

  String _typeLabel() {
    switch (expense.transactionType) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.deductions:
        return 'Deduction';
      case TransactionType.maaser:
        return 'Maaser';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor(context);
    final amountFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              child: Icon(_typeIcon()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat.yMMMd().format(expense.date)} · ${expense.hebrewDate}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _typeLabel(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountFormat.format(expense.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
