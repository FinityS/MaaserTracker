enum TransactionType {
  income,
  maaser,
  deductions;

  @override
  String toString() {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.maaser:
        return 'Maaser';
      case TransactionType.deductions:
        return 'Deductions';
      default:
        return super.toString();
    }
  }
}

