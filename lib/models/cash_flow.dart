import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/models/transaction_type.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

const transactionIcons = {
  TransactionType.income: Icons.attach_money,
  TransactionType.maaser: Icons.favorite,
};

class CashFlow {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final JewishDate hebrewDate;
  final TransactionType transactionType;

  CashFlow({
    required this.title,
    required this.amount,
    required this.date,
    required this.hebrewDate,
    required this.transactionType,
  }) : id = uuid.v4();

  String get formattedDate {
    return formatter.format(date);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'transactionType': transactionType.index,
    };
  }
}

