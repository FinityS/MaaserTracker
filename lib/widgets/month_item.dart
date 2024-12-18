import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';

import '../models/month_totals.dart';
import '../models/transaction_type.dart';



class MonthItem extends StatelessWidget {
  MonthItem({super.key});

  // Example of a hardcoded MonthTotals object
  final MonthTotals monthTotals = MonthTotals(
    title: 'Jul 2023',
    incomeAmount: 5000,
    maaserAmount: 550,
    date: DateTime.now(),
    hebrewDate: JewishDate(),
    transactionType: TransactionType.income,
  );


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: SizedBox(
        width: 250,
        height: 150,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  monthTotals.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  //String that represents maaserAmount / incomeAmount
                  'Maaser: \$${monthTotals.maaserAmount.toStringAsFixed(0)} / \$${monthTotals.incomeAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  //String that represents the percentage of maaserAmount out of incomeAmount
                  '(${(monthTotals.maaserAmount / monthTotals.incomeAmount * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            //insert horizontal line with low opacity
            Divider(
              color: Colors.grey.withOpacity(0.25),
              thickness: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  //String that represents amount of money left for maaserAmount to be 10% of incomeAmount
                  '\$${(monthTotals.incomeAmount * 0.1 - monthTotals.maaserAmount).toStringAsFixed(0)} until 10%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
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
