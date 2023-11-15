import 'package:flutter/material.dart';
import 'package:maaserTracker/widgets/expenses_item.dart';

import '../models/Expense.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList(
      {Key? key, required this.expenses, required this.onRemoveExpense})
      : super(key: key);

  final List<Expense> expenses;
  final void Function(Expense expense) onRemoveExpense;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) => Dismissible(
          key: ValueKey(expenses[index]),
          onDismissed: (direction) {
            // Remove the item from the data source.
            onRemoveExpense(expenses[index]);
          },
          child: ExpenseItem(expense: expenses[index])),
    );
  }
}
