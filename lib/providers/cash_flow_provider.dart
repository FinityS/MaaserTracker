import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maaserTracker/models/cash_flow.dart';
import 'package:maaserTracker/models/transaction_type.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/widgets/new_cash_flow.dart';

class CashFlowProvider extends ChangeNotifier {
  final List<CashFlow> _cashFlows = [];
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

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
}