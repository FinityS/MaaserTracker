import 'package:flutter/material.dart';

import '../models/Expense.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem({super.key, required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        children: [
          Text(expense.title),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('\$${expense.amount.toStringAsFixed(2)}'),
              const Spacer(),
              Row(
                children: [
                  Icon(transactionIcons[expense.transactionType]),
                  const SizedBox(width: 8),
                  Text(expense.formattedDate),
                  const SizedBox(width: 8),
                  Text(expense.hebrewDate.toString()),
                ],
              ),
            ],
          )
        ],
      ),
    ));
  }
}
