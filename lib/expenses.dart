import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maaserTracker/providers/cash_flow_provider.dart';
import 'package:maaserTracker/widgets/bar_chart_item.dart';
import 'package:maaserTracker/widgets/maaser_drawer.dart';
import 'package:provider/provider.dart';

import 'models/transaction_type.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  _ExpensesState createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateFormat.y().format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        final totalIncome = cashFlowProvider.getTotalIncomeForYear(_selectedYear!);
        final totalDeductions = cashFlowProvider.getTotalDeductionsForYear(_selectedYear!);
        final totalIncomeMinusDeductions = cashFlowProvider.getTotalIncomeMinusDeductionsForYear(_selectedYear!);
        final totalMaaser = cashFlowProvider.getTotalMaaserForYear(_selectedYear!);
        final maaserPercentage = cashFlowProvider.getMaaserPercentageForYear(_selectedYear!);


        final filteredExpenses = cashFlowProvider.getFilteredCashFlows(
          transactionType: TransactionType.income,
          year: _selectedYear,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            actions: [
              IconButton(
                onPressed: () => cashFlowProvider.openAddCashFlowOverlay(
                    context, TransactionType.income),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          drawer: const MaaserDrawer(
            selectedIndex: 0,
          ),
          body: Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Income: \$${totalIncome.toStringAsFixed(2)}'),
                    Text('Total Income Minus Deductions: \$${totalIncomeMinusDeductions.toStringAsFixed(2)}'),
                    Text('Total Maaser: \$${totalMaaser.toStringAsFixed(2)}'),
                    Text('Maaser Percentage: ${maaserPercentage.toStringAsFixed(2)}%'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) => BarChartItem(
                    label: filteredExpenses[index].title,
                    value: filteredExpenses[index].amount,
                    maxValue: 500, // Example max value
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