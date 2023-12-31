import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

enum Category {
  food,
  clothing,
  housing,
  transportation,
  medical,
  insurance,
  household,
  personal,
  debt,
  retirement,
  education,
  gifts,
  entertainment,
  other,
  charity
}

const categoryIcons = {
  Category.food: Icons.fastfood,
  Category.clothing: Icons.shopping_bag,
  Category.housing: Icons.home,
  Category.transportation: Icons.car_rental,
  Category.medical: Icons.medical_services,
  Category.insurance: Icons.local_hospital,
  Category.household: Icons.home_repair_service,
  Category.personal: Icons.person,
  Category.debt: Icons.money_off,
  Category.retirement: Icons.account_balance,
  Category.education: Icons.school,
  Category.gifts: Icons.card_giftcard,
  Category.entertainment: Icons.sports_esports,
  Category.other: Icons.more_horiz,
  Category.charity: Icons.favorite,
};

// method to calculate minutes in a day
int minutesInDay(DateTime date) {
  return date.hour * 60 + date.minute;
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = uuid.v4();

  String get formattedDate {
    return formatter.format(date);
  }
}

class ExpenseBucket {
  final Category category;
  final List<Expense> expenses;

  ExpenseBucket({
    required this.category,
    required this.expenses,
  });

  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
      : expenses = allExpenses
            .where((expense) => expense.category == category)
            .toList();

  double get totalAmount {
    double sum = 0;
    for (var expense in expenses) {
      sum += expense.amount;
    }
    return sum;
  }

  String get formattedTotalAmount {
    return '\$${totalAmount.toStringAsFixed(2)}';
  }
}
