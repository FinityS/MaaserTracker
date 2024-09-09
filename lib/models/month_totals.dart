import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/models/transaction_type.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

class MonthTotals {
  final String id;
  final String title;
  final double incomeAmount;
  final double maaserAmount;
  final DateTime date;
  final JewishDate hebrewDate;
  final TransactionType transactionType;

  MonthTotals({
    required this.title,
    required this.incomeAmount,
    required this.date,
    required this.hebrewDate,
    required this.transactionType,
    required this.maaserAmount,
  }) : id = uuid.v4();

  String get formattedDate {
    return formatter.format(date);
  }
}

