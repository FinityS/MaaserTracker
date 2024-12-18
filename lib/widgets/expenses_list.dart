import 'package:flutter/material.dart';
import 'package:maaserTracker/widgets/expenses_item.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_type.dart';
import '../providers/cash_flow_provider.dart';
import 'maaser_drawer.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key, this.transactionType});

  final TransactionType? transactionType;

  @override
  _ExpensesListState createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  String? _selectedMonth;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat.MMMM().format(DateTime.now());
    _selectedYear = DateFormat.y().format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        final filteredExpenses = cashFlowProvider.getFilteredCashFlows(
          transactionType: widget.transactionType,
          month: _selectedMonth,
          year: _selectedYear,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.transactionType == TransactionType.income
                  ? 'Income'
                  : widget.transactionType == TransactionType.maaser
                  ? 'Maaser'
                  : 'Maaser Deductions',
            ),
            actions: [
              IconButton(
                onPressed: () => cashFlowProvider.openAddCashFlowOverlay(
                    context, widget.transactionType!),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          drawer: MaaserDrawer(
            selectedIndex: widget.transactionType == TransactionType.income ? 1 : 2,
          ),
          body: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<String>(
                    value: _selectedMonth,
                    items: List.generate(12, (index) {
                      final month = DateFormat.MMMM().format(DateTime(0, index + 1));
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: _selectedYear,
                    items: List.generate(10, (index) {
                      final year = (DateTime.now().year - index).toString();
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => cashFlowProvider.openAddCashFlowOverlay(
                        context, filteredExpenses[index].transactionType,
                        cashFlow: filteredExpenses[index]),
                    child: ExpenseItem(expense: filteredExpenses[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}