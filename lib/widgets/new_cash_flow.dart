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
  bool _isSubmitting = false;

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
    if (_isSubmitting) {
      return;
    }

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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = Provider.of<CashFlowProvider>(context, listen: false);
      if (widget.cashFlow == null) {
        await provider.addCashFlow(newCashFlow);
      } else {
        await provider.updateCashFlow(newCashFlow);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteCashFlow() async {
    if (widget.cashFlow == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
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
    final theme = Theme.of(context);
    final formattedDate = _selectedDate == null
        ? 'No date chosen'
        : '${DateFormat.yMMMd().format(_selectedDate!)} · ${(_selectedHebrewDate ?? JewishDate.fromDateTime(_selectedDate!)).toString()}';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? 'Edit ${_selectedTransaction.toString()}'
            : 'Add ${_selectedTransaction.toString()}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Type',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<TransactionType>(
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
                                  label: Text('Deduction'),
                                  value: TransactionType.deductions,
                                  icon: Icon(Icons.money_off),
                                ),
                              ],
                              selected: <TransactionType>{_selectedTransaction},
                              onSelectionChanged:
                                  (Set<TransactionType> newSelection) {
                                setState(() {
                                  _selectedTransaction = newSelection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Describe the transaction',
                              prefixIcon: Icon(Icons.title),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
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
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,\.]'),
                              ),
                            ],
                            validator: (value) {
                              final parsedAmount = _parseAmount(value ?? '');
                              if (parsedAmount == null || parsedAmount <= 0) {
                                return 'Enter an amount greater than zero.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(formattedDate),
                      subtitle: _dateValidationMessage == null
                          ? const Text('Transaction date')
                          : Text(
                              _dateValidationMessage!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      trailing: FilledButton.tonalIcon(
                        onPressed: _presentDatePicker,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Change'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isSubmitting ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _saveCashFlow,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(isEditing ? Icons.save : Icons.add),
                          label: Text(isEditing ? 'Save' : 'Add'),
                        ),
                      ),
                    ],
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _deleteCashFlow,
                        icon: const Icon(Icons.delete_outline),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
