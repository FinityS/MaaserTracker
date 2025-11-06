import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:maaserTracker/providers/cash_flow_provider.dart';
import 'package:maaserTracker/widgets/cash_flow_tile.dart';
import 'package:maaserTracker/widgets/maaser_drawer.dart';
import 'package:provider/provider.dart';

import 'models/cash_flow.dart';
import 'models/transaction_type.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  _ExpensesState createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  late int _selectedGregorianYear;
  late int _selectedHebrewYear;
  bool _isHebrewYear = false;
  TransactionType? _recentFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedGregorianYear = now.year;
    _selectedHebrewYear = JewishDate.fromDateTime(now).getJewishYear();
    _recentFilter = null;
  }

  String get _activeYearString =>
      (_isHebrewYear ? _selectedHebrewYear : _selectedGregorianYear).toString();

  String get _yearPickerLabel =>
      _isHebrewYear ? '${_selectedHebrewYear.toString()} • Hebrew' : _selectedGregorianYear.toString();

  Future<void> _openYearPicker(CashFlowProvider provider) async {
    final availableGregorianYears = provider
        .getAvailableYears(null, false)
        .map(int.parse)
        .toList()
      ..sort();
    final availableHebrewYears = provider
        .getAvailableYears(null, true)
        .map(int.parse)
        .toList()
      ..sort();

    final selectedYear = await showModalBottomSheet<_YearPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isHebrew = _isHebrewYear;
        final availableGregorianSet = availableGregorianYears.toSet();
        final availableHebrewSet = availableHebrewYears.toSet();
        final currentGregorianYear = _selectedGregorianYear;
        final currentHebrewYear = _selectedHebrewYear;

        List<int> buildYears({required bool forHebrew}) {
          final source = forHebrew ? availableHebrewYears : availableGregorianYears;
          final currentYear = forHebrew ? currentHebrewYear : currentGregorianYear;
          final nowYear = forHebrew
              ? JewishDate.fromDateTime(DateTime.now()).getJewishYear()
              : DateTime.now().year;
          final effectiveCurrent = currentYear;
          final int maxYear = source.isNotEmpty
              ? max(source.last, effectiveCurrent)
              : max(nowYear, effectiveCurrent);
          final int minYear = source.isNotEmpty
              ? min(source.first, maxYear - 9)
              : maxYear - 9;
          final years = <int>[];
          for (int year = maxYear; year >= minYear; year--) {
            years.add(year);
          }
          return years;
        }

        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final years = buildYears(forHebrew: isHebrew);
              final yearsWithEntries = isHebrew ? availableHebrewSet : availableGregorianSet;
              final selectedYear = isHebrew ? currentHebrewYear : currentGregorianYear;

              return SingleChildScrollView(
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
                          color: Theme.of(context).colorScheme.outlineVariant,
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
                            onSelected: (_) {
                              if (isHebrew) {
                                setModalState(() {
                                  isHebrew = false;
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Hebrew'),
                            selected: isHebrew,
                            onSelected: (_) {
                              if (!isHebrew) {
                                setModalState(() {
                                  isHebrew = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a year',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final tileWidth = max((maxWidth - 48) / 3, 96.0);
                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: years
                                .map(
                                  (year) => SizedBox(
                                    width: tileWidth,
                                    child: _YearPickerTile(
                                      label: year.toString(),
                                      isSelected: year == selectedYear,
                                      hasEntries: yearsWithEntries.contains(year),
                                      onTap: () => Navigator.of(context).pop(
                                        _YearPickerResult(
                                          isHebrew: isHebrew,
                                          year: year,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
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

    if (!mounted || selectedYear == null) {
      return;
    }

    setState(() {
      _isHebrewYear = selectedYear.isHebrew;
      if (_isHebrewYear) {
        _selectedHebrewYear = selectedYear.year;
      } else {
        _selectedGregorianYear = selectedYear.year;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, cashFlowProvider, child) {
        final activeYear = _activeYearString;
        final isHebrewYear = _isHebrewYear;
        final totalIncome = cashFlowProvider.getTotalIncomeForYear(
          activeYear,
          isHebrew: isHebrewYear,
        );
        final totalDeductions = cashFlowProvider.getTotalDeductionsForYear(
          activeYear,
          isHebrew: isHebrewYear,
        );
        final totalIncomeMinusDeductions =
            cashFlowProvider.getTotalIncomeMinusDeductionsForYear(
          activeYear,
          isHebrew: isHebrewYear,
        );
        final totalMaaser = cashFlowProvider.getTotalMaaserForYear(
          activeYear,
          isHebrew: isHebrewYear,
        );
        final maaserPercentage = cashFlowProvider.getMaaserPercentageForYear(
          activeYear,
          isHebrew: isHebrewYear,
        );

        final maaserTarget = totalIncomeMinusDeductions * 0.10;
        final maaserLeftValue = max(maaserTarget - totalMaaser, 0);
        final maaserLeft = maaserLeftValue.toStringAsFixed(2);

        final transactionsForYear = cashFlowProvider.getFilteredCashFlows(
          year: activeYear,
          isHebrew: isHebrewYear,
        );
        final filteredRecentTransactions = transactionsForYear
            .where((cashFlow) => _recentFilter == null
                ? true
                : cashFlow.transactionType == _recentFilter)
            .take(5)
            .toList();

        final monthlySummaries = _MonthlySummary.buildForYear(
          cashFlows: transactionsForYear,
          year: isHebrewYear ? _selectedHebrewYear : _selectedGregorianYear,
          isHebrew: isHebrewYear,
          hebrewDateFormatter: cashFlowProvider.hebrewDateFormatter,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
          ),
          drawer: const MaaserDrawer(
            selectedIndex: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => cashFlowProvider.openAddCashFlowOverlay(
                context, TransactionType.income),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Year overview',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openYearPicker(cashFlowProvider),
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: Text(_yearPickerLabel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _StatCard(
                              label: 'Total Revenue',
                              value: totalIncome,
                              icon: Icons.trending_up_rounded,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              textColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            _StatCard(
                              label: 'Deductions',
                              value: totalDeductions,
                              icon: Icons.remove_circle_outline,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              textColor: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                            _StatCard(
                              label: 'Net Income',
                              value: totalIncomeMinusDeductions,
                              icon: Icons.account_balance_wallet_outlined,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                              textColor: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                            _StatCard(
                              label: 'Maaser Paid',
                              value: totalMaaser,
                              icon: Icons.volunteer_activism_rounded,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              textColor:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              footer:
                                  '(${maaserPercentage.toStringAsFixed(2)}%)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _MaaserProgressCard(
                          maaserTarget: maaserTarget,
                          maaserPaid: totalMaaser,
                          netIncome: totalIncomeMinusDeductions,
                          maaserLeftLabel: maaserLeft,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Monthly Snapshots',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _MonthlySummaryCarousel(summaries: monthlySummaries),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recent activity',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/activity',
                                  arguments: _recentFilter,
                                );
                              },
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildFilterChip(
                              label: 'All entries',
                              isSelected: _recentFilter == null,
                              onSelected: (_) {
                                setState(() {
                                  _recentFilter = null;
                                });
                              },
                            ),
                            _buildFilterChip(
                              label: 'Income',
                              isSelected:
                                  _recentFilter == TransactionType.income,
                              onSelected: (selected) {
                                setState(() {
                                  _recentFilter =
                                      selected ? TransactionType.income : null;
                                });
                              },
                            ),
                            _buildFilterChip(
                              label: 'Deductions',
                              isSelected:
                                  _recentFilter == TransactionType.deductions,
                              onSelected: (selected) {
                                setState(() {
                                  _recentFilter = selected
                                      ? TransactionType.deductions
                                      : null;
                                });
                              },
                            ),
                            _buildFilterChip(
                              label: 'Maaser',
                              isSelected:
                                  _recentFilter == TransactionType.maaser,
                              onSelected: (selected) {
                                setState(() {
                                  _recentFilter =
                                      selected ? TransactionType.maaser : null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (filteredRecentTransactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        transactionsForYear.isEmpty
                            ? 'Add your first entry to see it here.'
                            : 'No entries match this filter yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final cashFlow = filteredRecentTransactions[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index == filteredRecentTransactions.length - 1
                                      ? 0
                                      : 12,
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
                        childCount: filteredRecentTransactions.length,
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
    );
  }
}

class _YearPickerTile extends StatelessWidget {
  const _YearPickerTile({
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
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
              if (hasEntries) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  color: foregroundColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _YearPickerResult {
  const _YearPickerResult({
    required this.isHebrew,
    required this.year,
  });

  final bool isHebrew;
  final int year;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.footer,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final String? footer;

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
              Icon(icon, color: textColor.withOpacity(0.8)),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 6),
                Text(
                  footer!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.85),
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

class _MaaserProgressCard extends StatelessWidget {
  const _MaaserProgressCard({
    required this.maaserTarget,
    required this.maaserPaid,
    required this.netIncome,
    required this.maaserLeftLabel,
  });

  final double maaserTarget;
  final double maaserPaid;
  final double netIncome;
  final String maaserLeftLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final netForBar = netIncome <= 0 ? 1.0 : netIncome;
    final targetRatio = (maaserTarget / netForBar).clamp(0.0, 1.0);
    final paidRatio = (maaserPaid / netForBar).clamp(0.0, 1.0);
    final isAhead = maaserPaid >= maaserTarget && maaserTarget > 0;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Maaser Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              maaserTarget <= 0
                  ? 'Add income and deductions to see your 10% goal.'
                  : isAhead
                      ? 'You are ${currency.format(maaserPaid - maaserTarget)} ahead of the 10% goal!'
                      : 'You have \$$maaserLeftLabel left to reach 10% for this year.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _ProgressComparisonBar(
              label: 'Required (10%)',
              value: targetRatio,
              amount: maaserTarget,
              color: colorScheme.tertiary,
            ),
            const SizedBox(height: 12),
            _ProgressComparisonBar(
              label: 'Paid to date',
              value: paidRatio,
              amount: maaserPaid,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net income: ${currency.format(netIncome)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${(maaserTarget <= 0 ? 0 : (maaserPaid / netIncome * 100)).clamp(0, double.infinity).toStringAsFixed(2)}% paid to Maaser!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressComparisonBar extends StatelessWidget {
  const _ProgressComparisonBar({
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
  });

  final String label;
  final double value;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              currency.format(amount),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            value: value.clamp(0.0, 1.0),
          ),
        ),
      ],
    );
  }
}

class _MonthlySummaryCarousel extends StatelessWidget {
  const _MonthlySummaryCarousel({required this.summaries});

  final List<_MonthlySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final hasData = summaries.any((summary) => summary.hasData);
    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Text(
            'Add entries to start building your monthly snapshots.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final summary = summaries[index];
          return _MonthlySummaryCard(summary: summary);
        },
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.summary});

  final _MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final hasData = summary.hasData;

    return Opacity(
      opacity: hasData ? 1.0 : 0.55,
      child: SizedBox(
        width: 220,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Income: ${currency.format(summary.income)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Maaser: ${currency.format(summary.maaser)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: summary.progressForIndicator,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.netIncome <= 0
                      ? ''
                      : summary.maaser >= summary.target
                          ? 'Goal met!'
                          : '\$${summary.leftToGoal.toStringAsFixed(2)} to go',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlySummary {
  _MonthlySummary({
    required this.label,
    required this.income,
    required this.deductions,
    required this.maaser,
  });

  final String label;
  final double income;
  final double deductions;
  final double maaser;

  double get netIncome => income - deductions;
  double get target => max(netIncome * 0.10, 0);
  double get leftToGoal => max(target - maaser, 0);
  double get progress => target == 0 ? 0 : maaser / target;
  double get progressForIndicator => target == 0
      ? 0
      : (maaser / target).clamp(0.0, 1.0);
  bool get hasData => income > 0 || deductions > 0 || maaser > 0;

  static List<_MonthlySummary> buildForYear({
    required List<CashFlow> cashFlows,
    required int year,
    required bool isHebrew,
    required HebrewDateFormatter hebrewDateFormatter,
  }) {
    if (!isHebrew) {
      final incomeTotals = List<double>.filled(12, 0);
      final deductionTotals = List<double>.filled(12, 0);
      final maaserTotals = List<double>.filled(12, 0);

      for (final cashFlow in cashFlows) {
        final monthIndex = cashFlow.date.month - 1;
        if (monthIndex < 0 || monthIndex >= 12) {
          continue;
        }

        switch (cashFlow.transactionType) {
          case TransactionType.income:
            incomeTotals[monthIndex] += cashFlow.amount;
            break;
          case TransactionType.deductions:
            deductionTotals[monthIndex] += cashFlow.amount;
            break;
          case TransactionType.maaser:
            maaserTotals[monthIndex] += cashFlow.amount;
            break;
        }
      }

      return List.generate(12, (index) {
        final monthDate = DateTime(year, index + 1, 1);
        return _MonthlySummary(
          label: DateFormat.MMMM().format(monthDate),
          income: incomeTotals[index],
          deductions: deductionTotals[index],
          maaser: maaserTotals[index],
        );
      });
    }

    final jewishDate = JewishDate();
    jewishDate.setJewishDate(year, JewishDate.TISHREI, 1);
    final lastMonth =
        jewishDate.isJewishLeapYear() ? JewishDate.ADAR_II : JewishDate.ADAR;
    final monthCount = lastMonth - JewishDate.TISHREI + 1;
    final incomeTotals = List<double>.filled(monthCount, 0);
    final deductionTotals = List<double>.filled(monthCount, 0);
    final maaserTotals = List<double>.filled(monthCount, 0);

    for (final cashFlow in cashFlows) {
      final monthIndex =
          cashFlow.hebrewDate.getJewishMonth() - JewishDate.TISHREI;
      if (monthIndex < 0 || monthIndex >= monthCount) {
        continue;
      }

      switch (cashFlow.transactionType) {
        case TransactionType.income:
          incomeTotals[monthIndex] += cashFlow.amount;
          break;
        case TransactionType.deductions:
          deductionTotals[monthIndex] += cashFlow.amount;
          break;
        case TransactionType.maaser:
          maaserTotals[monthIndex] += cashFlow.amount;
          break;
      }
    }

    return List.generate(monthCount, (index) {
      final jewishMonth = JewishDate.TISHREI + index;
      final labelDate = JewishDate();
      labelDate.setJewishDate(year, jewishMonth, 1);
      return _MonthlySummary(
        label: hebrewDateFormatter.formatMonth(labelDate),
        income: incomeTotals[index],
        deductions: deductionTotals[index],
        maaser: maaserTotals[index],
      );
    });
  }
}

