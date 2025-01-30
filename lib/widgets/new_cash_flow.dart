import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/models/cash_flow.dart';
import 'package:maaserTracker/models/transaction_type.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:maaserTracker/providers/cash_flow_provider.dart';

class NewCashFlow extends StatefulWidget {
  final TransactionType transactionType;
  final CashFlow? cashFlow;

  const NewCashFlow({super.key, 
    required this.transactionType,
    this.cashFlow,
  });

  @override
  _NewCashFlowState createState() => _NewCashFlowState();
}

class _NewCashFlowState extends State<NewCashFlow> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  late TransactionType selectedTransaction;

  DateTime? _selectedDate;
  JewishDate? _selectedHebrewDate;

  @override
  void initState() {
    super.initState();
    if (widget.cashFlow != null) {
      _titleController.text = widget.cashFlow!.title;
      _amountController.text = widget.cashFlow!.amount.toStringAsFixed(2);
      _selectedDate = widget.cashFlow!.date;
      _selectedHebrewDate = widget.cashFlow!.hebrewDate;
    } else {
      _selectedDate = DateTime.now();
      _selectedHebrewDate = JewishDate.fromDateTime(_selectedDate!);
    }

    selectedTransaction = widget.transactionType;

    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        final enteredAmount = double.tryParse(_amountController.text);
        if (enteredAmount != null) {
          _amountController.text = enteredAmount.toStringAsFixed(2);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedHebrewDate = JewishDate.fromDateTime(pickedDate);
      });
    }
  }

  void _submitExpenseData() {
    final enteredAmount = double.tryParse(_amountController.text);
    final amountIsValid = enteredAmount != null && enteredAmount > 0;
    if (!amountIsValid || _selectedDate == null) {
      // Show error
      return;
    }

    final newCashFlow = CashFlow(
      title: _titleController.text.trim(),
      amount: enteredAmount,
      date: _selectedDate!,
      hebrewDate: _selectedHebrewDate!,
      transactionType: widget.transactionType,
    );

    Provider.of<CashFlowProvider>(context, listen: false).addCashFlow(newCashFlow);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cashFlow == null ? 'Add ${selectedTransaction.toString()}' : '${widget.cashFlow?.transactionType} Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        child: Column(
          children: [
            if (widget.cashFlow == null)
              SegmentedButton<TransactionType>(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.blue),
                shadowColor: WidgetStateProperty.all(Colors.blue),
                overlayColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.2)),

              ),
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  label: Text('Income'),
                  value: TransactionType.income,
                  icon: Icon(Icons.attach_money),
                ),
                ButtonSegment<TransactionType>(
                    label: Text('Maaser'),
                    value: TransactionType.maaser,
                    icon: Icon(Icons.volunteer_activism)),
                ButtonSegment<TransactionType>(
                    label: Text('Maaser Deductions'),
                    value: TransactionType.deductions,
                    icon: Icon(Icons.money_off)),
              ],
              selected: <TransactionType>{selectedTransaction},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  selectedTransaction = newSelection.first;
                });
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              controller: _titleController,
              readOnly: widget.cashFlow != null,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
              keyboardType: TextInputType.number,
              controller: _amountController,
              focusNode: _amountFocusNode,
              readOnly: widget.cashFlow != null,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedDate == null
                      ? 'No date chosen!'
                      : '${DateFormat.yMd().format(_selectedDate!)} ${_selectedHebrewDate!.toString()}'),
                ),
                if (widget.cashFlow == null)
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Icon(Icons.calendar_today),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                if (widget.cashFlow == null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitExpenseData,
                      child: const Text('Add'),
                    ),
                  ),
                if (widget.cashFlow != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.cashFlow != null) {
                          Provider.of<CashFlowProvider>(context, listen: false).deleteCashFlow(widget.cashFlow!);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}