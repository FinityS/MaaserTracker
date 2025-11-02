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
  bool _isHebrew = false;
  List<String> availableYears = [];
  List<String> availableMonths = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = 'Entire Year';
    _selectedYear = DateFormat.y().format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        availableYears = cashFlowProvider.getAvailableYears(widget.transactionType, _isHebrew);

        //if available years is empty, add the current year to the set
        if (availableYears.isEmpty) {
          availableYears.add(DateFormat.y().format(DateTime.now()));
        } else if (!availableYears.contains(_selectedYear)) {
          // If selected year is not available, select the most recent year to the present
          _selectedYear = availableYears.first;
        }


        availableMonths = cashFlowProvider.getAvailableMonths(widget.transactionType, _selectedYear, _isHebrew);

        // Ensure the selected month exists for the newly selected year
        if (_selectedMonth != null &&
            _selectedMonth != 'Entire Year' &&
            !availableMonths.contains(_selectedMonth)) {
          _selectedMonth = 'Entire Year';
        }


        final filteredExpenses = cashFlowProvider.getFilteredCashFlows(
          transactionType: widget.transactionType,
          month: _selectedMonth == 'Entire Year' ? null : _selectedMonth,
          year: _selectedYear,
          isHebrew: _isHebrew,
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
          ),
          drawer: MaaserDrawer(
            selectedIndex:
                widget.transactionType == TransactionType.income
                    ? 1
                    : widget.transactionType == TransactionType.maaser
                        ? 2
                        : 3,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => cashFlowProvider.openAddCashFlowOverlay(
                context, widget.transactionType!),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<String>(
                    value: _selectedMonth,
                    items: ['Entire Year', ...availableMonths].map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: _selectedYear,
                    items: availableYears.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                        // Update available months for the new year
                        availableMonths = cashFlowProvider.getAvailableMonths(
                            widget.transactionType, _selectedYear, _isHebrew);

                        // Reset the selected month if it's no longer available
                        if (_selectedMonth != null &&
                            _selectedMonth != 'Entire Year' &&
                            !availableMonths.contains(_selectedMonth)) {
                          _selectedMonth = 'Entire Year';
                        }
                      });
                    },
                  ),
                  Switch(
                    value: _isHebrew,
                    onChanged: (value) {
                      setState(() {
                        _isHebrew = value;
                        availableYears = cashFlowProvider.getAvailableYears(widget.transactionType, _isHebrew);
                        _selectedYear = availableYears.first;

                        availableMonths = cashFlowProvider.getAvailableMonths(widget.transactionType, _selectedYear, _isHebrew);
                        _selectedMonth = 'Entire Year';

                      });
                    },
                    activeColor: Colors.blue,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[300],
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
