import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maaserTracker/models/Expense.dart' as expense;

final formatter = DateFormat.yMd();

class NewExpense extends StatefulWidget {
  const NewExpense({Key? key, required this.onAddExpense}) : super(key: key);

  final void Function(expense.Expense expense) onAddExpense;

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  expense.Category? _selectedCategory;

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submitExpenseData() {
    final enteredAmount = double.tryParse(_amountController.text);
    final amountIsValid = enteredAmount != null && enteredAmount > 0;
    if (_titleController.text.trim().isEmpty ||
        !amountIsValid ||
        _selectedDate == null ||
        _selectedCategory == null) {
      // Show error
      return;
    }

    widget.onAddExpense(expense.Expense(
        title: _titleController.text.trim(),
        amount: enteredAmount,
        date: _selectedDate!,
        category: _selectedCategory!));

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
          TextField(
            decoration: const InputDecoration(labelText: 'Title'),
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
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(_selectedDate != null
                          ? formatter.format(_selectedDate!)
                          : 'No Date Chosen'),
                      IconButton(
                          onPressed: _presentDatePicker,
                          icon: const Icon(Icons.calendar_month)),
                    ]),
              ),
            ],
          ),
          const TextField(
            decoration: InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 16),
          Row(children: [
            DropdownButton(
                value: _selectedCategory,
                items: expense.Category.values
                    .map((category) => DropdownMenuItem(
                        value: category, child: Text(category.name)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    if (value is expense.Category) {
                      _selectedCategory = value;
                    }
                  });
                }),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: _submitExpenseData,
                child: const Text('Add Expense')),
          ])
        ],
      ),
    );
  }
}
