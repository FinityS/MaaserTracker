import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/widgets/expenses_item.dart';
import 'package:provider/provider.dart';

import '../models/transaction_type.dart';
import '../providers/cash_flow_provider.dart';
import 'maaser_drawer.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key, this.transactionType});

  final TransactionType? transactionType;

  @override
  _ExpensesListState createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  late DateTime _selectedGregorianMonth;
  late JewishDate _selectedHebrewMonth;
  bool _isHebrew = false;
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedGregorianMonth = DateTime(now.year, now.month);
    _selectedHebrewMonth = JewishDate.fromDateTime(now)
      ..setJewishDayOfMonth(1);
  }

  String _currentMonthLabel(CashFlowProvider provider) {
    if (_isHebrew) {
      return provider.hebrewDateFormatter.formatMonth(_selectedHebrewMonth);
    }
    return DateFormat.MMMM().format(_selectedGregorianMonth);
  }

  String _currentYearLabel() {
    if (_isHebrew) {
      return _selectedHebrewMonth.getJewishYear().toString();
    }
    return DateFormat.y().format(_selectedGregorianMonth);
  }

  void _syncHebrewFromGregorian() {
    final jewishDate = JewishDate.fromDateTime(_selectedGregorianMonth);
    jewishDate.setJewishDayOfMonth(1);
    _selectedHebrewMonth = jewishDate;
  }

  void _syncGregorianFromHebrew() {
    final gregorian = _selectedHebrewMonth.getGregorianCalendar();
    _selectedGregorianMonth = DateTime(gregorian.year, gregorian.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_isHebrew) {
        final previous = _selectedHebrewMonth.clone();
        previous.setJewishDayOfMonth(1);
        previous.back();
        previous.setJewishDayOfMonth(1);
        _selectedHebrewMonth = previous;
        _syncGregorianFromHebrew();
      } else {
        _selectedGregorianMonth = DateTime(
          _selectedGregorianMonth.year,
          _selectedGregorianMonth.month - 1,
        );
        _syncHebrewFromGregorian();
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_isHebrew) {
        final next = _selectedHebrewMonth.clone();
        next.setJewishDayOfMonth(1);
        next.forward(Calendar.MONTH, 1);
        next.setJewishDayOfMonth(1);
        _selectedHebrewMonth = next;
        _syncGregorianFromHebrew();
      } else {
        _selectedGregorianMonth = DateTime(
          _selectedGregorianMonth.year,
          _selectedGregorianMonth.month + 1,
        );
        _syncHebrewFromGregorian();
      }
    });
  }

  Future<void> _openMonthPicker(CashFlowProvider provider) async {
    final initialGregorian = _selectedGregorianMonth;
    final initialHebrew = _selectedHebrewMonth.clone();
    final result = await showModalBottomSheet<_MonthPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isHebrew = _isHebrew;
        int displayedGregorianYear = initialGregorian.year;
        int displayedHebrewYear = initialHebrew.getJewishYear();
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final textTheme = theme.textTheme;
            final colorScheme = theme.colorScheme;

            void updateCalendar(bool hebrew) {
              setModalState(() {
                isHebrew = hebrew;
              });
            }

            Widget buildYearHeader({
              required String label,
              required VoidCallback onPrevious,
              required VoidCallback onNext,
            }) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous year',
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      label,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next year',
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              );
            }

            Widget buildMonthGrid({
              required List<_MonthGridOption> options,
            }) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final targetWidth = math.max((maxWidth - 48) / 3, 96.0);
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: options
                        .map(
                          (option) => SizedBox(
                            width: targetWidth,
                            child: _MonthPickerTile(
                              label: option.label,
                              isSelected: option.isSelected,
                              hasEntries: option.hasEntries,
                              onTap: option.onTap,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            }

            List<_MonthGridOption> buildGregorianOptions() {
              final availableMonths = provider
                  .getAvailableMonths(
                    widget.transactionType,
                    displayedGregorianYear.toString(),
                    false,
                  )
                  .toSet();
              final monthNames = List.generate(12, (index) {
                final date = DateTime(displayedGregorianYear, index + 1, 1);
                final label = DateFormat.MMMM().format(date);
                final isSelected =
                    initialGregorian.year == displayedGregorianYear &&
                        initialGregorian.month == index + 1;
                final hasEntries = availableMonths.contains(label);
                return _MonthGridOption(
                  label: label,
                  isSelected: isSelected,
                  hasEntries: hasEntries,
                  onTap: () {
                    Navigator.of(context).pop(
                      _MonthPickerResult(
                        isHebrew: false,
                        gregorianMonth: DateTime(displayedGregorianYear, index + 1),
                      ),
                    );
                  },
                );
              });
              return monthNames;
            }

            List<_MonthGridOption> buildHebrewOptions() {
              final formatter = provider.hebrewDateFormatter;
              final jewishDate = JewishDate();
              jewishDate.setJewishDate(displayedHebrewYear, JewishDate.TISHREI, 1);
              final lastMonth = jewishDate.isJewishLeapYear()
                  ? JewishDate.ADAR_II
                  : JewishDate.ADAR;
              final availableMonths = provider
                  .getAvailableMonths(
                    widget.transactionType,
                    displayedHebrewYear.toString(),
                    true,
                  )
                  .toSet();

              final options = <_MonthGridOption>[];
              for (int month = JewishDate.TISHREI; month <= lastMonth; month++) {
                final current = JewishDate();
                current.setJewishDate(displayedHebrewYear, month, 1);
                final label = formatter.formatMonth(current);
                final isSelected =
                    initialHebrew.getJewishYear() == displayedHebrewYear &&
                        initialHebrew.getJewishMonth() == month;
                options.add(
                  _MonthGridOption(
                    label: label,
                    isSelected: isSelected,
                    hasEntries: availableMonths.contains(label),
                    onTap: () {
                      final chosen = JewishDate();
                      chosen.setJewishDate(displayedHebrewYear, month, 1);
                      Navigator.of(context).pop(
                        _MonthPickerResult(
                          isHebrew: true,
                          jewishMonth: chosen,
                        ),
                      );
                    },
                  ),
                );
              }
              return options;
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select month',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Gregorian'),
                            selected: !isHebrew,
                            onSelected: (_) => updateCalendar(false),
                          ),
                          ChoiceChip(
                            label: const Text('Hebrew'),
                            selected: isHebrew,
                            onSelected: (_) => updateCalendar(true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Column(
                          key: ValueKey<bool>(isHebrew),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isHebrew)
                              buildYearHeader(
                                label: displayedHebrewYear.toString(),
                                onPrevious: () {
                                  setModalState(() {
                                    displayedHebrewYear = math.max(3761, displayedHebrewYear - 1);
                                  });
                                },
                                onNext: () {
                                  setModalState(() {
                                    displayedHebrewYear++;
                                  });
                                },
                              )
                            else
                              buildYearHeader(
                                label: displayedGregorianYear.toString(),
                                onPrevious: () {
                                  setModalState(() {
                                    displayedGregorianYear = math.max(1, displayedGregorianYear - 1);
                                  });
                                },
                                onNext: () {
                                  setModalState(() {
                                    displayedGregorianYear++;
                                  });
                                },
                              ),
                            const SizedBox(height: 20),
                            buildMonthGrid(
                              options: isHebrew
                                  ? buildHebrewOptions()
                                  : buildGregorianOptions(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _isHebrew = result.isHebrew;
      if (result.isHebrew) {
        _selectedHebrewMonth = result.jewishMonth!;
        _syncGregorianFromHebrew();
      } else {
        _selectedGregorianMonth = result.gregorianMonth!;
        _syncHebrewFromGregorian();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        final monthLabel = _currentMonthLabel(cashFlowProvider);
        final yearLabel = _currentYearLabel();

        final filteredExpenses = cashFlowProvider.getFilteredCashFlows(
          transactionType: widget.transactionType,
          month: monthLabel,
          year: yearLabel,
          isHebrew: _isHebrew,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.transactionType == TransactionType.income
                  ? 'Income'
                  : widget.transactionType == TransactionType.maaser
                  ? 'Maaser'
                  : 'Maaser Deductions',
            ),
          ),
          drawer: MaaserDrawer(
            selectedIndex:
                widget.transactionType == TransactionType.income
                    ? 1
                    : widget.transactionType == TransactionType.maaser
                        ? 2
                        : 3,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => cashFlowProvider.openAddCashFlowOverlay(
                context, widget.transactionType!),
            child: const Icon(Icons.add),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              _horizontalDragDistance = 0;
            },
            onHorizontalDragUpdate: (details) {
              _horizontalDragDistance += details.delta.dx;
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() > 250) {
                if (velocity < 0) {
                  _goToNextMonth();
                } else {
                  _goToPreviousMonth();
                }
              } else if (_horizontalDragDistance.abs() > 80) {
                if (_horizontalDragDistance < 0) {
                  _goToNextMonth();
                } else {
                  _goToPreviousMonth();
                }
              }
              _horizontalDragDistance = 0;
            },
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Gregorian'),
                            selected: !_isHebrew,
                            onSelected: (value) {
                              if (!value || !_isHebrew) return;
                              setState(() {
                                _isHebrew = false;
                                _syncHebrewFromGregorian();
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Hebrew'),
                            selected: _isHebrew,
                            onSelected: (value) {
                              if (!value || _isHebrew) return;
                              setState(() {
                                _isHebrew = true;
                                _syncGregorianFromHebrew();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Previous month',
                            icon: const Icon(Icons.chevron_left_rounded, size: 28),
                            onPressed: _goToPreviousMonth,
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _openMonthPicker(cashFlowProvider),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      monthLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      yearLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Next month',
                            icon: const Icon(Icons.chevron_right_rounded, size: 28),
                            onPressed: _goToNextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swipe,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Swipe left or right anywhere to change the month',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => cashFlowProvider.openAddCashFlowOverlay(
                          context, filteredExpenses[index].transactionType,
                          cashFlow: filteredExpenses[index]),
                      child: ExpenseItem(expense: filteredExpenses[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthGridOption {
  const _MonthGridOption({
    required this.label,
    required this.isSelected,
    required this.hasEntries,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool hasEntries;
  final VoidCallback onTap;
}

class _MonthPickerTile extends StatelessWidget {
  const _MonthPickerTile({
    required this.label,
    required this.isSelected,
    required this.hasEntries,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool hasEntries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor =
        isSelected ? colorScheme.primaryContainer : colorScheme.surfaceVariant;
    final foregroundColor =
        isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasEntries ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: hasEntries
                        ? colorScheme.secondary
                        : foregroundColor.withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasEntries ? 'Has entries' : 'No entries',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foregroundColor.withOpacity(hasEntries ? 0.9 : 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPickerResult {
  const _MonthPickerResult({
    required this.isHebrew,
    this.gregorianMonth,
    this.jewishMonth,
  });

  final bool isHebrew;
  final DateTime? gregorianMonth;
  final JewishDate? jewishMonth;
}
