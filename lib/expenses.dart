import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/models/Expense.dart';
import 'package:maaserTracker/widgets/expenses_list.dart';
import 'package:maaserTracker/widgets/maaser_drawer.dart';
import 'package:maaserTracker/widgets/new_expense.dart';

import 'models/transaction.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _registeredExpenses = [
    Expense(
      title: 'Rent',
      amount: 1000.00,
      date: DateTime.now(),
      hebrewDate: JewishDate(),
      transactionType: Transaction.income,
    ),
  ];

  void _openAddExpenseOverlay(Transaction transactionType) {
    showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        builder: (ctx) => NewExpense(
              onAddExpense: _addExpense,
              transactionType: transactionType,
            ));
  }

  void _addExpense(Expense expense) {
    setState(() {
      _registeredExpenses.add(expense);
    });
  }

  void _removeExpense(Expense expense) {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Expense removed!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _registeredExpenses.insert(expenseIndex, expense);
            });
          },
        )));
  }

  void handleScreenChanged(int selectedScreen) {
    if (selectedScreen == 1 || selectedScreen == 2) {
      Widget newScreen = ExpensesList(
        expenses: _registeredExpenses,
        onRemoveExpense: _removeExpense,
        transactionType:
            selectedScreen == 1 ? Transaction.income : Transaction.maaser,
        onAddExpense: _openAddExpenseOverlay,
      );

      Navigator.of(context).pop();

      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return newScreen;
      }));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => _openAddExpenseOverlay(Transaction.income),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: MaaserDrawer(
        onDestinationSelected: handleScreenChanged,
        selectedIndex: 0,
      ),
      body: Center( child:  Card(
        elevation: 4.0,
        child: Container(
          width: 200,
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Jul 2023',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '9%',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: 0.09,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '\$550 / \$5000',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$50 left to 10%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )) ,
    );
  }
}
