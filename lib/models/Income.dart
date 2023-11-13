import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

class Income {
  final String id;
  final String title;
  final double amount;
  final DateTime date;

  //icon that represents income
  static const Icon icon = Icon(Icons.attach_money);

  Income({
    required this.title,
    required this.amount,
    required this.date,
  }) : id = uuid.v4();

  String get formattedDate {
    return formatter.format(date);
  }
}
