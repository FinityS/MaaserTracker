import 'package:flutter/material.dart';
import 'package:maaserTracker/widgets/expenses_item.dart';
import 'package:provider/provider.dart';

import '../models/transaction_type.dart';
import '../providers/cash_flow_provider.dart';
import 'maaser_drawer.dart';

class ExpensesList extends StatelessWidget {

  const ExpensesList(
      {super.key, this.transactionType});

  final TransactionType? transactionType;

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        final filteredExpenses = transactionType != null
            ? cashFlowProvider.cashFlows
            .where((expense) => expense.transactionType == transactionType)
            .toList()
            : cashFlowProvider.cashFlows;

        return Scaffold(
          appBar: AppBar(
            title: Text(// Title depends on the transactionType
              transactionType == TransactionType.income
                  ? 'Income'
                  : transactionType == TransactionType.maaser
                  ? 'Maaser'
                  : 'Maaser Deductions',
            ),
            actions: [
              IconButton(
                onPressed: () => cashFlowProvider.openAddCashFlowOverlay(context, transactionType!),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          drawer: MaaserDrawer(
            selectedIndex: transactionType == TransactionType.income ? 1 : 2,
          ),
          body: ListView.builder(
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => cashFlowProvider.openAddCashFlowOverlay(
                  context, filteredExpenses[index].transactionType,
                  cashFlow: filteredExpenses[index]),
              child: ExpenseItem(expense: filteredExpenses[index]),
            ),
          ),
        );
      },
    );

  }
}
