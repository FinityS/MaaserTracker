import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/models/transaction.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

const transactionIcons = {
  Transaction.income: Icons.attach_money,
  Transaction.maaser: Icons.favorite,
};

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final JewishDate hebrewDate;
  final Transaction transactionType;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.hebrewDate,
    required this.transactionType,
  }) : id = uuid.v4();

  String get formattedDate {
    return formatter.format(date);
  }
}

