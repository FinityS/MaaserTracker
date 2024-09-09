import 'package:flutter/material.dart';
import 'package:maaserTracker/providers/cash_flow_provider.dart';
import 'package:maaserTracker/widgets/bar_chart_item.dart';
import 'package:maaserTracker/widgets/maaser_drawer.dart';
import 'package:provider/provider.dart';

import 'models/transaction_type.dart';

class Expenses extends StatelessWidget {
  const Expenses({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => Provider.of<CashFlowProvider>(context, listen: false)
                .openAddCashFlowOverlay(context, TransactionType.income),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: const MaaserDrawer(
        selectedIndex: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BarChartItem(label: "Maaser", value: 300, maxValue: 500),
            BarChartItem(label: "Income", value: 100, maxValue: 340),
          ],
        ),
      ),
    );
  }
}
