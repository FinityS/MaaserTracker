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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  late TransactionType _selectedTransaction;

  DateTime? _selectedDate;
  JewishDate? _selectedHebrewDate;
  String? _dateValidationMessage;

  @override
  void initState() {
    super.initState();
    _selectedTransaction =
        widget.cashFlow?.transactionType ?? widget.transactionType;

    if (widget.cashFlow != null) {
      _titleController.text = widget.cashFlow!.title;
      _amountController.text = widget.cashFlow!.amount.toStringAsFixed(2);
      _selectedDate = widget.cashFlow!.date;
      _selectedHebrewDate = widget.cashFlow!.hebrewDate;
    } else {
      _selectedDate = DateTime.now();
      _selectedHebrewDate = JewishDate.fromDateTime(_selectedDate!);
    }

    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        final parsedAmount = _parseAmount(_amountController.text);
        if (parsedAmount != null) {
          _amountController.text = parsedAmount.toStringAsFixed(2);
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
        _dateValidationMessage = null;
      });
    }
  }

  double? _parseAmount(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (sanitized.isEmpty) {
      return null;
    }

    final normalized = sanitized.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _saveCashFlow() async {
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid) {
      return;
    }

    if (_selectedDate == null) {
      setState(() {
        _dateValidationMessage = 'Please choose a date.';
      });
      return;
    }

    final parsedAmount = _parseAmount(_amountController.text)!;

    final newCashFlow = CashFlow(
      id: widget.cashFlow?.id,
      title: _titleController.text.trim(),
      amount: parsedAmount,
      date: _selectedDate!,
      hebrewDate:
          _selectedHebrewDate ?? JewishDate.fromDateTime(_selectedDate!),
      transactionType: _selectedTransaction,
    );

    final provider = Provider.of<CashFlowProvider>(context, listen: false);
    if (widget.cashFlow == null) {
      await provider.addCashFlow(newCashFlow);
    } else {
      await provider.updateCashFlow(newCashFlow);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteCashFlow() async {
    if (widget.cashFlow == null) {
      return;
    }

    final provider = Provider.of<CashFlowProvider>(context, listen: false);
    await provider.deleteCashFlow(widget.cashFlow!);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cashFlow != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? 'Edit ${_selectedTransaction.toString()}'
            : 'Add ${_selectedTransaction.toString()}'),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<TransactionType>(
                  segments: const <ButtonSegment<TransactionType>>[
                    ButtonSegment<TransactionType>(
                      label: Text('Income'),
                      value: TransactionType.income,
                      icon: Icon(Icons.attach_money),
                    ),
                    ButtonSegment<TransactionType>(
                      label: Text('Maaser'),
                      value: TransactionType.maaser,
                      icon: Icon(Icons.volunteer_activism),
                    ),
                    ButtonSegment<TransactionType>(
                      label: Text('Maaser Deductions'),
                      value: TransactionType.deductions,
                      icon: Icon(Icons.money_off),
                    ),
                  ],
                  selected: <TransactionType>{_selectedTransaction},
                  onSelectionChanged: (Set<TransactionType> newSelection) {
                    setState(() {
                      _selectedTransaction = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Describe the transaction',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a title.';
                    }
                    if (value.trim().length < 3) {
                      return 'Use at least 3 characters for the title.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  validator: (value) {
                    final parsedAmount = _parseAmount(value ?? '');
                    if (parsedAmount == null || parsedAmount <= 0) {
                      return 'Enter an amount greater than zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'No date chosen'
                                : '${DateFormat.yMd().format(_selectedDate!)}  ·  ${_selectedHebrewDate ?? JewishDate.fromDateTime(_selectedDate!).toString()}',
                          ),
                          if (_dateValidationMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _dateValidationMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _presentDatePicker,
                      child: const Icon(Icons.calendar_today),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveCashFlow,
                        child: Text(isEditing ? 'Save' : 'Add'),
                      ),
                    ),
                  ],
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _deleteCashFlow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}