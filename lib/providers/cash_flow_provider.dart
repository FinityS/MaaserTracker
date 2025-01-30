import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maaserTracker/models/cash_flow.dart';
import 'package:maaserTracker/models/transaction_type.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/widgets/new_cash_flow.dart';
import 'package:intl/intl.dart';

class CashFlowProvider extends ChangeNotifier {
  final List<CashFlow> _cashFlows = [];
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  final HebrewDateFormatter hebrewDateFormatter = HebrewDateFormatter();

  List<CashFlow> get cashFlows => _cashFlows;

  void loadCashFlows() {
    if (_user != null) {
      _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cashFlows')
          .get()
          .then((snapshot) {
        final cashFlows = snapshot.docs
            .map((doc) => CashFlow(
          title: doc['title'],
          amount: doc['amount'],
          date: DateTime.fromMillisecondsSinceEpoch(doc['date']),
          hebrewDate: JewishDate.fromDateTime(
              DateTime.fromMillisecondsSinceEpoch(doc['date'])),
          transactionType: TransactionType.values[doc['transactionType']],
        ))
            .toList();
        _cashFlows.addAll(cashFlows);
        notifyListeners();
      });
    }
  }

  List<String> getAvailableMonths(TransactionType? transactionType, String? year, bool isHebrew) {
    final months = _cashFlows.where((cashFlow) {
      final matchesTransactionType = transactionType == null || cashFlow.transactionType == transactionType;
      final matchesYear = year == null || (isHebrew
          ? cashFlow.hebrewDate.getJewishYear().toString() == year
          : DateFormat.y().format(cashFlow.date) == year);
      return matchesTransactionType && matchesYear;
    }).map((cashFlow) {
      return isHebrew
          ? hebrewDateFormatter.formatMonth(cashFlow.hebrewDate)
          : DateFormat.MMMM().format(cashFlow.date);
    }).toSet().toList();
    months.sort((a, b) => monthOrder[a]!.compareTo(monthOrder[b]!));
    return months;
  }

  List<String> getAvailableYears(TransactionType? transactionType, bool isHebrew) {
    final years = _cashFlows.where((cashFlow) {
      return transactionType == null || cashFlow.transactionType == transactionType;
    }).map((cashFlow) {
      return isHebrew
          ? cashFlow.hebrewDate.getJewishYear().toString()
          : DateFormat.y().format(cashFlow.date);
    }).toSet().toList();
    years.sort((a, b) => a.compareTo(b));
    return years;
  }

  List<CashFlow> getFilteredCashFlows({
    TransactionType? transactionType,
    String? month,
    String? year,
    bool isHebrew = false,
  }) {
    return _cashFlows.where((cashFlow) {
      final matchesTransactionType = transactionType == null || cashFlow.transactionType == transactionType;
      final matchesMonth = month == null || (isHebrew
          ? hebrewDateFormatter.formatMonth(cashFlow.hebrewDate) == month
          : DateFormat.MMMM().format(cashFlow.date) == month);
      final matchesYear = year == null || (isHebrew
          ? cashFlow.hebrewDate.getJewishYear().toString() == year
          : DateFormat.y().format(cashFlow.date) == year);
      return matchesTransactionType && matchesMonth && matchesYear;
    }).toList();
  }


  void addCashFlow(CashFlow expense) {
    _cashFlows.add(expense);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final firestoreInstance = FirebaseFirestore.instance;
      firestoreInstance
          .collection('users')
          .doc(user.uid)
          .collection('cashFlows')
          .add(expense.toMap());
    }
  }

  void deleteCashFlow(CashFlow expense) {
    _cashFlows.remove(expense);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final firestoreInstance = FirebaseFirestore.instance;
      firestoreInstance
          .collection('users')
          .doc(user.uid)
          .collection('cashFlows')
          .doc(expense.id)
          .delete();
    }
  }

  void openAddCashFlowOverlay(BuildContext context, TransactionType transactionType, {CashFlow? cashFlow}) {
    showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        builder: (ctx) => NewCashFlow(
          transactionType: transactionType,
          cashFlow: cashFlow,
        ));
  }

  double getTotalIncomeForYear(String year) {
    return _cashFlows
        .where((cashFlow) => cashFlow.transactionType == TransactionType.income && DateFormat.y().format(cashFlow.date) == year)
        .fold(0.0, (sum, cashFlow) => sum + cashFlow.amount);
  }

  double getTotalDeductionsForYear(String year) {
    return _cashFlows
        .where((cashFlow) => cashFlow.transactionType == TransactionType.deductions && DateFormat.y().format(cashFlow.date) == year)
        .fold(0.0, (sum, cashFlow) => sum + cashFlow.amount);
  }

  double getTotalMaaserForYear(String year) {
    return _cashFlows
        .where((cashFlow) => cashFlow.transactionType == TransactionType.maaser && DateFormat.y().format(cashFlow.date) == year)
        .fold(0.0, (sum, cashFlow) => sum + cashFlow.amount);
  }

  double getTotalIncomeMinusDeductionsForYear(String year) {
    return getTotalIncomeForYear(year) - getTotalDeductionsForYear(year);
  }

  double getMaaserPercentageForYear(String year) {
    final totalIncomeMinusDeductions = getTotalIncomeMinusDeductionsForYear(year);
    if (totalIncomeMinusDeductions == 0) return 0;
    return (getTotalMaaserForYear(year) / totalIncomeMinusDeductions) * 100;
  }

  static const monthOrder = {
    // Gregorian months
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
    // Hebrew months
    'Nisan': 13,
    'Iyar': 14,
    'Sivan': 15,
    'Tammuz': 16,
    'Av': 17,
    'Elul': 18,
    'Tishrei': 19,
    'Cheshvan': 20,
    'Kislev': 21,
    'Tevet': 22,
    'Shevat': 23,
    'Adar': 24,
    'Adar I': 25, // For leap years
    'Adar II': 26, // For leap years
  };

}