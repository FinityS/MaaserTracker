import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import  'package:maaser_tracker/models/Expense.dart' as expense;
import 'package:intl/intl.dart';

final formatter = DateFormat.yMd();

class NewExpense extends StatefulWidget {
  const NewExpense({Key? key}) : super(key: key);

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
    if(_titleController.text.trim().isEmpty || !amountIsValid ||
        _selectedDate == null || _selectedCategory == null) {
      return;
    }

}

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Title'),
            controller: _titleController,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',),
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
                    Text( _selectedDate !=null ? formatter.format(_selectedDate!) : 'No Date Chosen'),
                    IconButton(
                        onPressed: _presentDatePicker,
                        icon: const Icon(Icons.calendar_month)),
                  ]
                ),
              ),
            ],
          ),

          TextField(
            decoration: InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DropdownButton(
                value: _selectedCategory,
                items: expense.Category.values.map((category) =>
                DropdownMenuItem(
                                value: category,
                                child: Text(category.name))).toList(),
                                onChanged: (value) {
                setState(() {
                  if (value is expense.Category) {
                    _selectedCategory = value;
                  }
                });
    }),
              ElevatedButton(onPressed: () {
                Navigator.of(context).pop();
              }, child: Text('Cancel')),
              ElevatedButton(onPressed: _submitExpenseData, child: Text('Add Expense')),
            ]
          )

        ],
      ),
    );}

}

