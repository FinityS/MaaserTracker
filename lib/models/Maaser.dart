import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

class Maaser {

  final String id;
  final String title;
  final double amount;
  final DateTime date;

  //icon that represents giving charity
  static const Icon icon = Icon(Icons.favorite);

  Maaser({
    required this.title,
    required this.amount,
    required this.date,
  }) : id = uuid.v4();

  String get formattedDate {
    return formatter.format(date);
  }

}

