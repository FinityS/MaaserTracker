import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/models/Expense.dart' as expense;
import '../models/Expense.dart';
import '../models/transaction.dart';

final formatter = DateFormat.yMd();

class NewExpense extends StatefulWidget {



  const NewExpense({super.key, required this.onAddExpense, required this.transactionType });

  final void Function(expense.Expense expense) onAddExpense;
  final Transaction transactionType;

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> {
  late Transaction selectedTransaction;

  @override
  void initState() {
    super.initState();
    selectedTransaction = widget.transactionType;
  }

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  JewishDate? _selectedHebrewDate;

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    setState(() {
      _selectedDate = pickedDate;
      _selectedHebrewDate = JewishDate.fromDateTime(pickedDate!);
    });
  }

  void _submitExpenseData() {
    final enteredAmount = double.tryParse(_amountController.text);
    final amountIsValid = enteredAmount != null && enteredAmount > 0;
    if (_titleController.text.trim().isEmpty ||
        !amountIsValid ||
        _selectedDate == null) {
      // Show error
      return;
    }

    widget.onAddExpense(expense.Expense(
        title: _titleController.text.trim(),
        amount: enteredAmount,
        date: _selectedDate!,
        hebrewDate: _selectedHebrewDate!,
        transactionType: selectedTransaction
        ));

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          SegmentedButton<Transaction>(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all(Colors.blue),
              shadowColor: MaterialStateProperty.all(Colors.blue),
              overlayColor: MaterialStateProperty.all(Colors.blue.withOpacity(0.2)),

            ),
            segments: const <ButtonSegment<Transaction>>[
              ButtonSegment<Transaction>(
                  label: Text('Income'),
                  value: Transaction.income,
                  icon: Icon(Icons.attach_money),
              ),
              ButtonSegment<Transaction>(
                  label: Text('Maaser'),
                  value: Transaction.maaser,
                  icon: Icon(Icons.volunteer_activism)),
            ],
            selected: <Transaction>{selectedTransaction!},
            onSelectionChanged: (Set<Transaction> newSelection) {
              setState(() {
                selectedTransaction = newSelection.first;
              });
            },
          ),
          TextField(
            decoration: InputDecoration(
              labelText: 'Title',
            ),
            controller: _titleController,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  controller: _amountController,
                ),
              ),

            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(_selectedDate == null
                    ? 'No date chosen!'
                    : 'Picked Date: ${formatter.format(_selectedDate!)} ${_selectedHebrewDate!.toString()}'),
              ),
              TextButton(
                onPressed: _presentDatePicker,
                child: Icon(Icons.calendar_today),
              ),
            ],
          ),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitExpenseData,
                child: const Text('Add'),
              ),
            ),
          ])
        ],
      ),
    );
  }
}
