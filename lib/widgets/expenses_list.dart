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

  String _getDateFilterLabel() {
    final language = _isHebrew ? 'Hebrew' : 'English';
    if (_selectedMonth == null || _selectedYear == null) {
      return 'Date Filter ($language)';
    }
    if (_selectedMonth == 'Entire Year') {
      return '$_selectedYear ($language)';
    }
    return '${_selectedMonth!} $_selectedYear ($language)';
  }

  Future<void> _openDateFilterDialog(
      BuildContext context, CashFlowProvider cashFlowProvider) async {
    String? tempMonth = _selectedMonth;
    String? tempYear = _selectedYear;
    bool tempIsHebrew = _isHebrew;
    List<String> tempYears = List.from(availableYears);
    List<String> tempMonths = List.from(availableMonths);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Date Filter'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hebrew Dates'),
                      Switch(
                        value: tempIsHebrew,
                        onChanged: (value) {
                          setState(() {
                            tempIsHebrew = value;
                            tempYears = cashFlowProvider.getAvailableYears(
                                widget.transactionType, tempIsHebrew);
                            if (tempYears.isEmpty) {
                              tempYears.add(
                                  DateFormat.y().format(DateTime.now()));
                            }
                            tempYear = tempYears.first;
                            tempMonths = cashFlowProvider.getAvailableMonths(
                                widget.transactionType,
                                tempYear,
                                tempIsHebrew);
                            tempMonth = 'Entire Year';
                          });
                        },
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: tempYear,
                    items: tempYears
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        tempYear = value;
                        tempMonths = cashFlowProvider.getAvailableMonths(
                            widget.transactionType,
                            tempYear,
                            tempIsHebrew);
                        if (!tempMonths.contains(tempMonth) &&
                            tempMonth != 'Entire Year') {
                          tempMonth = 'Entire Year';
                        }
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: tempMonth,
                    items: ['Entire Year', ...tempMonths]
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        tempMonth = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {
                    'month': tempMonth,
                    'year': tempYear,
                    'isHebrew': tempIsHebrew,
                  }),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedMonth = result['month'];
        _selectedYear = result['year'];
        _isHebrew = result['isHebrew'];
      });
    }
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
            selectedIndex: widget.transactionType == TransactionType.income ? 1 : 2,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => cashFlowProvider.openAddCashFlowOverlay(
                context, widget.transactionType!),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () =>
                      _openDateFilterDialog(context, cashFlowProvider),
                  child: Text(_getDateFilterLabel()),
                ),
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
