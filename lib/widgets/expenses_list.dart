import 'package:flutter/material.dart';
import 'package:maaserTracker/widgets/expenses_item.dart';

import '../models/Expense.dart';
import '../models/transaction.dart';
import 'maaser_drawer.dart';

class ExpensesList extends StatelessWidget {

  const ExpensesList(
      {super.key, required this.expenses, required this.onRemoveExpense, this.transactionType, required this.onAddExpense});

  final List<Expense> expenses;
  final void Function(Expense expense) onRemoveExpense;
  final Transaction? transactionType;
  final void Function(Transaction transactionType) onAddExpense;


  @override
  Widget build(BuildContext context) {

    // filter the expenses list based on the transaction type
    final filteredExpenses = transactionType != null
        ? expenses.where((expense) => expense.transactionType == transactionType).toList()
        : expenses;

    return Scaffold(
      appBar: AppBar(
        title: Text( transactionType ==  Transaction.income ? 'Income' : "Maaser"),
        actions: [
          IconButton(
            onPressed: () => onAddExpense(transactionType!),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: MaaserDrawer(
        onDestinationSelected: (int selectedScreen) {
          if (selectedScreen == 0) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          } else if ((selectedScreen == 1 && transactionType !=  Transaction.income)
            || (selectedScreen == 2 && transactionType !=  Transaction.maaser)) {
            Widget newScreen = ExpensesList(
              expenses: expenses,
              onRemoveExpense: onRemoveExpense,
              transactionType: selectedScreen == 1 ? Transaction.income : Transaction.maaser,
              onAddExpense: onAddExpense,
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => newScreen),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
        selectedIndex: transactionType ==  Transaction.income ? 1 : 2,
      ),
      body: ListView.builder(
        itemCount: filteredExpenses.length,
        itemBuilder: (context, index) => Dismissible(
            key: ValueKey(filteredExpenses[index]),
            onDismissed: (direction) {
              // Remove the item from the data source.
              onRemoveExpense(filteredExpenses[index]);
            },
            child: ExpenseItem(expense: filteredExpenses[index])),
      ),
    );

  }
}
