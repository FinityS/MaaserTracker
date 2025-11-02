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
  String? _selectedMonth;
  String? _selectedYear;
  bool _isHebrew = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat.MMMM().format(now);
    _selectedYear = DateFormat.y().format(now);
    _pageController = PageController(
      initialPage: now.month - 1,
      viewportFraction: 0.65,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        final formatter = cashFlowProvider.hebrewDateFormatter;

        var availableYears =
            cashFlowProvider.getAvailableYears(widget.transactionType, _isHebrew);
        if (availableYears.isEmpty) {
          final fallbackYear = _isHebrew
              ? JewishDate.fromDateTime(DateTime.now())
                  .getJewishYear()
                  .toString()
              : DateFormat.y().format(DateTime.now());
          availableYears = [fallbackYear];
        } else {
          availableYears = availableYears.reversed.toList();
        }

        if (_selectedYear == null || !availableYears.contains(_selectedYear)) {
          _selectedYear = availableYears.first;
        }

        final monthsWithEntries = cashFlowProvider
            .getAvailableMonths(widget.transactionType, _selectedYear, _isHebrew)
            .toSet();
        final allMonths = cashFlowProvider.getMonthsForYear(
          _selectedYear,
          _isHebrew,
        );

        if (allMonths.isNotEmpty) {
          if (_selectedMonth == null || !allMonths.contains(_selectedMonth)) {
            final currentMonth = _isHebrew
                ? formatter
                    .formatMonth(JewishDate.fromDateTime(DateTime.now()))
                : DateFormat.MMMM().format(DateTime.now());
            _selectedMonth =
                allMonths.contains(currentMonth) ? currentMonth : allMonths.first;
          }
        }

        final currentMonthIndex = _selectedMonth != null
            ? allMonths.indexOf(_selectedMonth!)
            : 0;

        final controllerPage = _pageController.hasClients
            ? _pageController.page?.round()
            : _pageController.initialPage;
        if (currentMonthIndex >= 0 && controllerPage != currentMonthIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                currentMonthIndex,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        final filteredExpenses = cashFlowProvider.getFilteredCashFlows(
          transactionType: widget.transactionType,
          month: _selectedMonth,
          year: _selectedYear,
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
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(20),
                          isSelected: [!_isHebrew, _isHebrew],
                          onPressed: (index) {
                            if ((index == 1) != _isHebrew) {
                              setState(() {
                                _isHebrew = index == 1;
                                if (_isHebrew) {
                                  final currentHebrewDate =
                                      JewishDate.fromDateTime(DateTime.now());
                                  _selectedYear =
                                      currentHebrewDate.getJewishYear().toString();
                                  _selectedMonth =
                                      formatter.formatMonth(currentHebrewDate);
                                } else {
                                  final now = DateTime.now();
                                  _selectedYear = DateFormat.y().format(now);
                                  _selectedMonth =
                                      DateFormat.MMMM().format(now);
                                }
                              });
                            }
                          },
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 110),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('Gregorian'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('Hebrew'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: availableYears
                                  .map(
                                    (year) => Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 4),
                                      child: ChoiceChip(
                                        label: Text(year),
                                        selected: year == _selectedYear,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedYear = year;
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentMonthIndex > 0
                              ? () {
                                  final previousIndex = currentMonthIndex - 1;
                                  _pageController.animateToPage(
                                    previousIndex,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                  );
                                  setState(() {
                                    _selectedMonth = allMonths[previousIndex];
                                  });
                                }
                              : null,
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 100,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                if (index >= 0 && index < allMonths.length) {
                                  setState(() {
                                    _selectedMonth = allMonths[index];
                                  });
                                }
                              },
                              itemCount: allMonths.length,
                              itemBuilder: (context, index) {
                                final monthName = allMonths[index];
                                final hasEntries = monthsWithEntries.contains(monthName);
                                final isSelected = index == currentMonthIndex;
                                return _MonthSelectionCard(
                                  label: monthName,
                                  hasEntries: hasEntries,
                                  isSelected: isSelected,
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentMonthIndex < allMonths.length - 1
                              ? () {
                                  final nextIndex = currentMonthIndex + 1;
                                  _pageController.animateToPage(
                                    nextIndex,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                  );
                                  setState(() {
                                    _selectedMonth = allMonths[nextIndex];
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Swipe left or right to change the month',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedMonth != null && _selectedYear != null
                          ? 'Showing $_selectedMonth $_selectedYear ${_isHebrew ? '(Hebrew calendar)' : '(Gregorian calendar)'}'
                          : '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
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
        );
      },
    );
  }
}

class _MonthSelectionCard extends StatelessWidget {
  const _MonthSelectionCard({
    required this.label,
    required this.hasEntries,
    required this.isSelected,
  });

  final String label;
  final bool hasEntries;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceVariant;
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outline;
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
    );
    final defaultStatusColor =
        theme.textTheme.bodySmall?.color ?? colorScheme.onSurfaceVariant;
    final statusStyle = theme.textTheme.bodySmall?.copyWith(
      color: isSelected
          ? colorScheme.onPrimaryContainer.withOpacity(0.8)
          : defaultStatusColor.withOpacity(0.7),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 12,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      hasEntries ? colorScheme.secondary : colorScheme.outline,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: labelStyle, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(
                      hasEntries ? 'Entries available' : 'No entries yet',
                      style: statusStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
