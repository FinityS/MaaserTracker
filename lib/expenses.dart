import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maaserTracker/providers/cash_flow_provider.dart';
import 'package:maaserTracker/widgets/bar_chart_item.dart';
import 'package:maaserTracker/widgets/maaser_drawer.dart';
import 'package:provider/provider.dart';
import 'dart:math';

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

        final maaserTarget = totalIncomeMinusDeductions * 0.10;
        final maaserLeftValue = max(maaserTarget - totalMaaser, 0);
        final maaserLeft = maaserLeftValue.toStringAsFixed(2);

        final filteredExpenses = cashFlowProvider.getFilteredCashFlows(
          transactionType: TransactionType.income,
          year: _selectedYear,
        );
        final recentTransactions = filteredExpenses.take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
          ),
          drawer: const MaaserDrawer(
            selectedIndex: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => cashFlowProvider.openAddCashFlowOverlay(
                context, TransactionType.income),
            child: const Icon(Icons.add),
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
              if (maaserLeftValue > 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BarChartItem(
                    label: '\$$maaserLeft Maaser Left to 10%',
                    value: totalMaaser,
                    maxValue: maaserTarget,
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: recentTransactions.isEmpty
                    ? const Center(
                        child: Text('Add your first income to see it here.'),
                      )
                    : ListView.separated(
                        itemCount: recentTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemBuilder: (context, index) {
                          final cashFlow = recentTransactions[index];
                          return ListTile(
                            title: Text(cashFlow.title),
                            subtitle: Text(
                              '${DateFormat.yMMMd().format(cashFlow.date)} · ${cashFlow.hebrewDate}',
                            ),
                            trailing: Text(
                              NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                                  .format(cashFlow.amount),
                            ),
                            onTap: () => cashFlowProvider.openAddCashFlowOverlay(
                              context,
                              cashFlow.transactionType,
                              cashFlow: cashFlow,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

