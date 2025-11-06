import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cash_flow.dart';
import '../models/transaction_type.dart';

class CashFlowTile extends StatelessWidget {
  const CashFlowTile({
    super.key,
    required this.cashFlow,
    this.onTap,
  });

  final CashFlow cashFlow;
  final VoidCallback? onTap;

  Color _typeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (cashFlow.transactionType) {
      case TransactionType.income:
        return colorScheme.primary;
      case TransactionType.deductions:
        return colorScheme.secondary;
      case TransactionType.maaser:
        return colorScheme.tertiary;
    }
  }

  IconData _typeIcon() {
    switch (cashFlow.transactionType) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.deductions:
        return Icons.remove_circle_outline;
      case TransactionType.maaser:
        return Icons.volunteer_activism_rounded;
    }
  }

  String _typeLabel() {
    switch (cashFlow.transactionType) {
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
    final amountFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final color = _typeColor(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
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
                      cashFlow.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat.yMMMd().format(cashFlow.date)} · ${cashFlow.hebrewDate}',
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
                amountFormat.format(cashFlow.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
