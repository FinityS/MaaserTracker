import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/models/cash_flow.dart';
import 'package:maaserTracker/models/transaction_type.dart';
import 'package:maaserTracker/widgets/new_cash_flow.dart';

class CashFlowProvider extends ChangeNotifier {
  final List<CashFlow> _cashFlows = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HebrewDateFormatter hebrewDateFormatter = HebrewDateFormatter();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cashFlowSubscription;
  User? _user;

  CashFlowProvider() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_handleAuthChange);
  }

  List<CashFlow> get cashFlows => List.unmodifiable(_cashFlows);

  void _handleAuthChange(User? user) {
    _user = user;
    _cashFlows.clear();
    _cashFlowSubscription?.cancel();

    if (user == null) {
      notifyListeners();
      return;
    }

    _cashFlowSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cashFlows')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(_handleCashFlowSnapshot);
  }

  void _handleCashFlowSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    final cashFlows = snapshot.docs.map((doc) {
      final data = doc.data();
      final rawDate = data['date'];
      final millisecondsSinceEpoch = rawDate is Timestamp
          ? rawDate.millisecondsSinceEpoch
          : (rawDate as num).toInt();
      final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);

      return CashFlow(
        id: data.containsKey('id') ? data['id'] as String : doc.id,
        title: data['title'] as String,
        amount: (data['amount'] as num).toDouble(),
        date: date,
        hebrewDate: JewishDate.fromDateTime(date),
        transactionType: TransactionType.values[data['transactionType'] as int],
      );
    }).toList();

    _cashFlows
      ..clear()
      ..addAll(cashFlows);
    notifyListeners();
  }

  List<String> getAvailableMonths(
      TransactionType? transactionType, String? year, bool isHebrew) {
    final months = _cashFlows.where((cashFlow) {
      final matchesTransactionType =
          transactionType == null || cashFlow.transactionType == transactionType;
      final matchesYear = year == null ||
          (isHebrew
              ? cashFlow.hebrewDate.getJewishYear().toString() == year
              : DateFormat.y().format(cashFlow.date) == year);
      return matchesTransactionType && matchesYear;
    }).map((cashFlow) {
      return isHebrew
          ? hebrewDateFormatter.formatMonth(cashFlow.hebrewDate)
          : DateFormat.MMMM().format(cashFlow.date);
    }).toSet().toList();

    months.sort((a, b) =>
        (monthOrder[a] ?? _fallbackMonthOrder(a))
            .compareTo(monthOrder[b] ?? _fallbackMonthOrder(b)));
    return months;
  }

  List<String> getMonthsForYear(String? year, bool isHebrew) {
    if (isHebrew) {
      final fallbackYear = JewishDate.fromDateTime(DateTime.now())
          .getJewishYear()
          .toString();
      final parsedYear = int.tryParse(year ?? fallbackYear) ??
          JewishDate.fromDateTime(DateTime.now()).getJewishYear();

      final jewishDate = JewishDate();
      jewishDate.setJewishDate(parsedYear, JewishDate.TISHREI, 1);
      final lastMonth =
          jewishDate.isJewishLeapYear() ? JewishDate.ADAR_II : JewishDate.ADAR;

      final months = <String>[];
      for (int month = JewishDate.TISHREI; month <= lastMonth; month++) {
        final currentMonth = JewishDate();
        currentMonth.setJewishDate(parsedYear, month, 1);
        months.add(hebrewDateFormatter.formatMonth(currentMonth));
      }
      return months;
    } else {
      final fallbackYear = DateFormat.y().format(DateTime.now());
      final parsedYear = int.tryParse(year ?? fallbackYear) ?? DateTime.now().year;
      return List.generate(
        12,
        (index) => DateFormat.MMMM().format(
          DateTime(parsedYear, index + 1, 1),
        ),
      );
    }
  }

  List<String> getAvailableYears(TransactionType? transactionType, bool isHebrew) {
    final years = _cashFlows.where((cashFlow) {
      return transactionType == null ||
          cashFlow.transactionType == transactionType;
    }).map((cashFlow) {
      return isHebrew
          ? cashFlow.hebrewDate.getJewishYear().toString()
          : DateFormat.y().format(cashFlow.date);
    }).toSet().toList();

    years.sort((a, b) {
      if (isHebrew) {
        return int.parse(a).compareTo(int.parse(b));
      }
      return a.compareTo(b);
    });
    return years;
  }

  List<CashFlow> getFilteredCashFlows({
    TransactionType? transactionType,
    String? month,
    String? year,
    bool isHebrew = false,
  }) {
    final filtered = _cashFlows.where((cashFlow) {
      final matchesTransactionType =
          transactionType == null || cashFlow.transactionType == transactionType;
      final matchesMonth = month == null ||
          (isHebrew
              ? hebrewDateFormatter.formatMonth(cashFlow.hebrewDate) == month
              : DateFormat.MMMM().format(cashFlow.date) == month);
      final matchesYear = year == null ||
          (isHebrew
              ? cashFlow.hebrewDate.getJewishYear().toString() == year
              : DateFormat.y().format(cashFlow.date) == year);
      return matchesTransactionType && matchesMonth && matchesYear;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> addCashFlow(CashFlow expense) async {
    final user = _user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cashFlows')
        .doc(expense.id)
        .set(expense.toMap());
  }

  Future<void> updateCashFlow(CashFlow expense) async {
    final user = _user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cashFlows')
        .doc(expense.id)
        .set(expense.toMap());
  }

  Future<void> deleteCashFlow(CashFlow expense) async {
    final user = _user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cashFlows')
        .doc(expense.id)
        .delete();
  }

  void openAddCashFlowOverlay(BuildContext context, TransactionType transactionType,
      {CashFlow? cashFlow}) {
    showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        builder: (ctx) => NewCashFlow(
              transactionType: transactionType,
              cashFlow: cashFlow,
            ));
  }

  double getTotalIncomeForYear(String year, {bool isHebrew = false}) {
    return _cashFlows
        .where((cashFlow) =>
            cashFlow.transactionType == TransactionType.income &&
            (isHebrew
                ? cashFlow.hebrewDate.getJewishYear().toString() == year
                : DateFormat.y().format(cashFlow.date) == year))
        .fold(0.0, (total, cashFlow) => total + cashFlow.amount);
  }

  double getTotalDeductionsForYear(String year, {bool isHebrew = false}) {
    return _cashFlows
        .where((cashFlow) =>
            cashFlow.transactionType == TransactionType.deductions &&
            (isHebrew
                ? cashFlow.hebrewDate.getJewishYear().toString() == year
                : DateFormat.y().format(cashFlow.date) == year))
        .fold(0.0, (total, cashFlow) => total + cashFlow.amount);
  }

  double getTotalMaaserForYear(String year, {bool isHebrew = false}) {
    return _cashFlows
        .where((cashFlow) =>
            cashFlow.transactionType == TransactionType.maaser &&
            (isHebrew
                ? cashFlow.hebrewDate.getJewishYear().toString() == year
                : DateFormat.y().format(cashFlow.date) == year))
        .fold(0.0, (total, cashFlow) => total + cashFlow.amount);
  }

  double getTotalIncomeMinusDeductionsForYear(String year,
      {bool isHebrew = false}) {
    return getTotalIncomeForYear(year, isHebrew: isHebrew) -
        getTotalDeductionsForYear(year, isHebrew: isHebrew);
  }

  double getMaaserPercentageForYear(String year, {bool isHebrew = false}) {
    final totalIncomeMinusDeductions =
        getTotalIncomeMinusDeductionsForYear(year, isHebrew: isHebrew);
    if (totalIncomeMinusDeductions == 0) return 0;
    return (getTotalMaaserForYear(year, isHebrew: isHebrew) /
            totalIncomeMinusDeductions) *
        100;
  }

  static const monthOrder = {
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
    'Adar I': 25,
    'Adar II': 26,
  };

  int _fallbackMonthOrder(String month) {
    return 100 + month.hashCode.abs();
  }

  @override
  void dispose() {
    _cashFlowSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
