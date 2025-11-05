import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';

import '../models/cash_flow.dart';
import '../models/transaction_type.dart';
import '../providers/cash_flow_provider.dart';
import 'cash_flow_tile.dart';
import 'maaser_drawer.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key, this.initialTransactionType});

  final TransactionType? initialTransactionType;

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  TransactionType? _activeFilter;
  bool _isHebrew = false;
  late DateTime _selectedGregorianMonth;
  late JewishDate _selectedHebrewMonth;
  String? _pendingScrollSectionId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _activeFilter = widget.initialTransactionType;
    _selectedGregorianMonth = DateTime(now.year, now.month);
    _selectedHebrewMonth = JewishDate.fromDateTime(now)..setJewishDayOfMonth(1);
  }

  @override
  void didUpdateWidget(covariant ExpensesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTransactionType != oldWidget.initialTransactionType &&
        widget.initialTransactionType != _activeFilter) {
      _activeFilter = widget.initialTransactionType;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _sectionId(bool isHebrew, String yearLabel, String monthLabel) {
    return '${isHebrew ? 'hebrew' : 'gregorian'}|$yearLabel|$monthLabel';
  }

  DateTime _gregorianMonthFor(JewishDate jewishDate) {
    final clone = jewishDate.clone();
    clone.setJewishDayOfMonth(1);
    final gregorian = clone.getGregorianCalendar();
    return DateTime(gregorian.year, gregorian.month);
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

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _setFilter(TransactionType? filter) {
    if (_activeFilter == filter) {
      return;
    }
    setState(() {
      _activeFilter = filter;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToTop();
      }
    });
  }

  int _drawerIndex() {
    if (_activeFilter == null) {
      return 1;
    }
    switch (_activeFilter!) {
      case TransactionType.income:
        return 2;
      case TransactionType.maaser:
        return 3;
      case TransactionType.deductions:
        return 4;
    }
  }

  String _titleForFilter() {
    if (_activeFilter == null) {
      return 'Activity';
    }
    switch (_activeFilter!) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.maaser:
        return 'Maaser';
      case TransactionType.deductions:
        return 'Maaser Deductions';
    }
  }

  List<_MonthSection> _buildSections(
    CashFlowProvider provider,
    List<CashFlow> cashFlows,
  ) {
    final sections = <String, _MonthSection>{};
    for (final cashFlow in cashFlows) {
      final monthLabel = _isHebrew
          ? provider.hebrewDateFormatter.formatMonth(cashFlow.hebrewDate)
          : DateFormat.MMMM().format(cashFlow.date);
      final yearLabel = _isHebrew
          ? cashFlow.hebrewDate.getJewishYear().toString()
          : DateFormat.y().format(cashFlow.date);
      final id = _sectionId(_isHebrew, yearLabel, monthLabel);
      final key = _sectionKeys.putIfAbsent(id, () => GlobalKey());
      final sortDate = _isHebrew
          ? _gregorianMonthFor(cashFlow.hebrewDate)
          : DateTime(cashFlow.date.year, cashFlow.date.month);

      final section = sections.putIfAbsent(
        id,
        () => _MonthSection(
          id: id,
          monthLabel: monthLabel,
          yearLabel: yearLabel,
          isHebrew: _isHebrew,
          sortDate: sortDate,
          key: key,
        ),
      );

      section.items.add(cashFlow);
      switch (cashFlow.transactionType) {
        case TransactionType.income:
          section.incomeTotal += cashFlow.amount;
          break;
        case TransactionType.deductions:
          section.deductionTotal += cashFlow.amount;
          break;
        case TransactionType.maaser:
          section.maaserTotal += cashFlow.amount;
          break;
      }
    }

    final orderedSections = sections.values.toList()
      ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return orderedSections;
  }

  _MonthSection? _findSection(List<_MonthSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) {
        return section;
      }
    }
    return null;
  }

  void _schedulePendingScroll(List<_MonthSection> sections) {
    final targetId = _pendingScrollSectionId;
    if (targetId == null) {
      return;
    }

    final targetSection = _findSection(sections, targetId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (targetSection != null && targetSection.key.currentContext != null) {
        await Scrollable.ensureVisible(
          targetSection.key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No entries for that month yet.'),
          ),
        );
      }
      _pendingScrollSectionId = null;
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

        return SafeArea(
          child: StatefulBuilder(
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
                      _activeFilter,
                      displayedGregorianYear.toString(),
                      false,
                    )
                    .toSet();

                return List.generate(12, (index) {
                  final date = DateTime(displayedGregorianYear, index + 1, 1);
                  final label = DateFormat.MMMM().format(date);
                  final isSelected = initialGregorian.year == displayedGregorianYear &&
                      initialGregorian.month == index + 1 &&
                      !isHebrew;

                  return _MonthGridOption(
                    label: label,
                    isSelected: isSelected,
                    hasEntries: availableMonths.contains(label),
                    onTap: () {
                      Navigator.of(context).pop(
                        _MonthPickerResult(
                          isHebrew: false,
                          gregorianMonth: date,
                        ),
                      );
                    },
                  );
                });
              }

              List<_MonthGridOption> buildHebrewOptions() {
                final availableMonths = provider
                    .getAvailableMonths(
                      _activeFilter,
                      displayedHebrewYear.toString(),
                      true,
                    )
                    .toSet();
                final months = provider.getMonthsForYear(
                  displayedHebrewYear.toString(),
                  true,
                );

                return List.generate(months.length, (index) {
                  final label = months[index];
                  final isSelected =
                      initialHebrew.getJewishYear() == displayedHebrewYear &&
                          provider.hebrewDateFormatter.formatMonth(initialHebrew) ==
                              label &&
                          isHebrew;

                  return _MonthGridOption(
                    label: label,
                    isSelected: isSelected,
                    hasEntries: availableMonths.contains(label),
                    onTap: () {
                      final jewishMonth = JewishDate()
                        ..setJewishDate(
                          displayedHebrewYear,
                          index + JewishDate.TISHREI,
                          1,
                        );
                      Navigator.of(context).pop(
                        _MonthPickerResult(
                          isHebrew: true,
                          jewishMonth: jewishMonth,
                        ),
                      );
                    },
                  );
                });
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
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
                      const SizedBox(height: 16),
                      Text(
                        'Select a month',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!isHebrew) ...[
                        buildYearHeader(
                          label: displayedGregorianYear.toString(),
                          onPrevious: () {
                            setModalState(() {
                              displayedGregorianYear--;
                            });
                          },
                          onNext: () {
                            setModalState(() {
                              displayedGregorianYear++;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        buildMonthGrid(options: buildGregorianOptions()),
                      ] else ...[
                        buildYearHeader(
                          label: '$displayedHebrewYear • Hebrew',
                          onPrevious: () {
                            setModalState(() {
                              displayedHebrewYear--;
                            });
                          },
                          onNext: () {
                            setModalState(() {
                              displayedHebrewYear++;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        buildMonthGrid(options: buildHebrewOptions()),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
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
        final gregorian = _selectedHebrewMonth.getGregorianCalendar();
        _selectedGregorianMonth = DateTime(gregorian.year, gregorian.month);
      } else {
        _selectedGregorianMonth = result.gregorianMonth!;
        _selectedHebrewMonth = JewishDate.fromDateTime(_selectedGregorianMonth)
          ..setJewishDayOfMonth(1);
      }
      final monthLabel = _currentMonthLabel(provider);
      final yearLabel = _currentYearLabel();
      _pendingScrollSectionId = _sectionId(_isHebrew, yearLabel, monthLabel);
    });
  }

  void _handleAdd(CashFlowProvider provider) {
    if (_activeFilter != null) {
      provider.openAddCashFlowOverlay(context, _activeFilter!);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.trending_up_rounded),
                title: const Text('Add income'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  provider.openAddCashFlowOverlay(
                    context,
                    TransactionType.income,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Add deduction'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  provider.openAddCashFlowOverlay(
                    context,
                    TransactionType.deductions,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.volunteer_activism_rounded),
                title: const Text('Add maaser'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  provider.openAddCashFlowOverlay(
                    context,
                    TransactionType.maaser,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        final filteredExpenses = cashFlowProvider.getFilteredCashFlows(
          transactionType: _activeFilter,
        );
        final sections = _buildSections(cashFlowProvider, filteredExpenses);
        _schedulePendingScroll(sections);

        final monthLabel = _currentMonthLabel(cashFlowProvider);
        final yearLabel = _currentYearLabel();

        return Scaffold(
          appBar: AppBar(
            title: Text(_titleForFilter()),
          ),
          drawer: MaaserDrawer(selectedIndex: _drawerIndex()),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _handleAdd(cashFlowProvider),
            child: const Icon(Icons.add),
          ),
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildFilterChip(
                            label: 'All entries',
                            isSelected: _activeFilter == null,
                            onSelected: () => _setFilter(null),
                          ),
                          _buildFilterChip(
                            label: 'Income',
                            isSelected: _activeFilter == TransactionType.income,
                            onSelected: () => _setFilter(TransactionType.income),
                          ),
                          _buildFilterChip(
                            label: 'Deductions',
                            isSelected:
                                _activeFilter == TransactionType.deductions,
                            onSelected: () =>
                                _setFilter(TransactionType.deductions),
                          ),
                          _buildFilterChip(
                            label: 'Maaser',
                            isSelected: _activeFilter == TransactionType.maaser,
                            onSelected: () =>
                                _setFilter(TransactionType.maaser),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: sections.isEmpty
                            ? null
                            : () => _openMonthPicker(cashFlowProvider),
                        icon: const Icon(Icons.calendar_month),
                        label: Text('Jump to $monthLabel $yearLabel'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _activeFilter == null
                            ? 'Add your first entry to start tracking activity.'
                            : 'No entries for this category yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                )
              else ...[
                for (final section in sections) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        key: section.key,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${section.monthLabel} ${section.yearLabel}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            _MonthlySummaryRow(section: section),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final cashFlow = section.items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == section.items.length - 1 ? 0 : 12,
                            ),
                            child: CashFlowTile(
                              cashFlow: cashFlow,
                              onTap: () => cashFlowProvider
                                  .openAddCashFlowOverlay(
                                context,
                                cashFlow.transactionType,
                                cashFlow: cashFlow,
                              ),
                            ),
                          );
                        },
                        childCount: section.items.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthlySummaryRow extends StatelessWidget {
  const _MonthlySummaryRow({required this.section});

  final _MonthSection section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          label: 'Income',
          value: section.incomeTotal,
          icon: Icons.trending_up_rounded,
          backgroundColor: colorScheme.primaryContainer,
          textColor: colorScheme.onPrimaryContainer,
        ),
        _SummaryCard(
          label: 'Deductions',
          value: section.deductionTotal,
          icon: Icons.remove_circle_outline,
          backgroundColor: colorScheme.secondaryContainer,
          textColor: colorScheme.onSecondaryContainer,
        ),
        _SummaryCard(
          label: 'Maaser',
          value: section.maaserTotal,
          icon: Icons.volunteer_activism_rounded,
          backgroundColor: colorScheme.tertiaryContainer,
          textColor: colorScheme.onTertiaryContainer,
        ),
        _SummaryCard(
          label: 'Net',
          value: section.netTotal,
          icon: Icons.account_balance_wallet_outlined,
          backgroundColor: colorScheme.surfaceContainerHighest,
          textColor: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Card(
        elevation: 0,
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor.withOpacity(0.85)),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                currency.format(value),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSection {
  _MonthSection({
    required this.id,
    required this.monthLabel,
    required this.yearLabel,
    required this.isHebrew,
    required this.sortDate,
    required this.key,
  });

  final String id;
  final String monthLabel;
  final String yearLabel;
  final bool isHebrew;
  final DateTime sortDate;
  final GlobalKey key;
  final List<CashFlow> items = [];
  double incomeTotal = 0;
  double deductionTotal = 0;
  double maaserTotal = 0;

  double get netTotal => incomeTotal - deductionTotal - maaserTotal;
}

class _MonthGridOption {
  _MonthGridOption({
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
    final backgroundColor = isSelected
        ? colorScheme.primary
        : hasEntries
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceVariant;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : hasEntries
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!hasEntries && !isSelected) ...[
                const SizedBox(height: 6),
                Text(
                  'No entries',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foregroundColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPickerResult {
  _MonthPickerResult({
    required this.isHebrew,
    this.gregorianMonth,
    this.jewishMonth,
  });

  final bool isHebrew;
  final DateTime? gregorianMonth;
  final JewishDate? jewishMonth;
}
