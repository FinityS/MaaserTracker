import 'package:flutter/material.dart';
import 'package:maaser_tracker/widgets/expenses_item.dart';
import '../models/Expense.dart';


class ExpensesList extends StatelessWidget {
  const ExpensesList({Key? key, required this.expenses}) : super(key: key);
  
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemCount: expenses.length,
      itemBuilder: (context, index) => ExpenseItem(expense: expenses[index]), );
  }
}