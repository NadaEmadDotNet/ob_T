import 'package:flutter/material.dart';
import 'package:obligation__tracker/pages/AddObligationPage.dart';
import 'package:obligation__tracker/pages/EditObligationPage.dart';
import 'package:obligation__tracker/pages/SearchPage.dart';
import 'package:obligation__tracker/pages/StatisticsPage.dart';
import 'package:obligation__tracker/pages/UserSettingPage.dart';
import 'package:obligation__tracker/services/api_service.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class ObligationsScreen extends StatefulWidget {
  const ObligationsScreen({super.key});

  @override
  State<ObligationsScreen> createState() => _ObligationsScreenState();
}

class _ObligationsScreenState extends State<ObligationsScreen> {
  late Future<List<Map<String, dynamic>>> _obligationsFuture;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadObligations();
  }

  void _loadObligations() {
    _obligationsFuture = ApiService.getObligations();
  }

  Future<void> _refresh() async {
    setState(_loadObligations);
    await _obligationsFuture;
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push(context, premiumRoute(const AddObligationPage()));
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _DashboardTab(future: _obligationsFuture, onRefresh: _refresh),
      const StatisticsPage(embedded: true),
      const UserSettingsPage(embedded: true),
    ];

    return Scaffold(
      extendBody: true,
      floatingActionButton: AnimatedScale(
        scale: _tabIndex == 0 ? 1 : 0.92,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: FloatingActionButton.extended(
          heroTag: 'add-obligation-fab',
          onPressed: _openAdd,
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 12,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
      ),
      body: AppBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(_tabIndex),
            child: tabs[_tabIndex],
          ),
        ),
      ),
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _tabIndex,
        onChanged: (index) => setState(() => _tabIndex = index),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final Future<void> Function() onRefresh;

  const _DashboardTab({
    required this.future,
    required this.onRefresh,
  });

  int _sum(List<Map<String, dynamic>> docs, String key) {
    return docs.fold(0, (sum, data) => sum + ((data[key] ?? 0) as num).toInt());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final docs = snapshot.data ?? [];
        final total = _sum(docs, 'amount');
        final paid = _sum(docs, 'paid');
        final remaining = total - paid;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: true,
              expandedHeight: 142,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton.filledTonal(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        premiumRoute(SearchPage(onChanged: onRefresh)),
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Obligation Tracker',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Payments, due dates, and priorities in one calm place.',
                        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _SummaryPanel(total: total, paid: paid, remaining: remaining),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Obligations',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(height: 620, child: SkeletonList())
                    else if (snapshot.hasError)
                      _StatePanel(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load obligations',
                        message: snapshot.error.toString(),
                      )
                    else if (docs.isEmpty)
                      const _StatePanel(
                        icon: Icons.assignment_rounded,
                        title: 'Nothing due yet',
                        message: 'Add your first obligation and it will show up here.',
                      )
                    else
                      RefreshIndicator(
                        onRefresh: onRefresh,
                        color: AppColors.teal,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) => _StaggeredItem(
                            index: index,
                            child: _ObligationCard(
                              obligation: docs[index],
                              index: index,
                              onRefresh: onRefresh,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final int total;
  final int paid;
  final int remaining;

  const _SummaryPanel({
    required this.total,
    required this.paid,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepTeal.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MetricTile(icon: Icons.account_balance_wallet_rounded, label: 'Total', value: '\$$total'),
              _MetricTile(icon: Icons.check_circle_rounded, label: 'Paid', value: '\$$paid'),
              _MetricTile(icon: Icons.pending_actions_rounded, label: 'Left', value: '\$$remaining'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          FittedBox(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligationCard extends StatefulWidget {
  final Map<String, dynamic> obligation;
  final int index;
  final Future<void> Function() onRefresh;

  const _ObligationCard({
    required this.obligation,
    required this.index,
    required this.onRefresh,
  });

  @override
  State<_ObligationCard> createState() => _ObligationCardState();
}

class _ObligationCardState extends State<_ObligationCard> {
  bool _pressed = false;

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.obligation;
    final docId = data['_id'].toString();
    final title = data['title']?.toString() ?? 'Untitled';
    final category = data['category']?.toString() ?? 'Others';
    final priority = obligationPriority(data);
    final amount = ((data['amount'] ?? 0) as num).toDouble();
    final paid = ((data['paid'] ?? 0) as num).toDouble();
    final progress = amount > 0 ? paid / amount : 0.0;
    final status = obligationStatusLabel(data);
    final isPaid = obligationIsPaid(data);
    final accent = isPaid ? AppColors.green : priorityColor(priority);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE9FBF5), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(_pressed ? 0.11 : 0.17),
                blurRadius: _pressed ? 16 : 26,
                offset: Offset(0, _pressed ? 8 : 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'obligation-$docId',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(categoryIcon(category), color: accent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$category - Due ${_formatDate(data['dueDate'])}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (priority != null) PriorityBadge(priority: priority),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '\$${paid.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    ' / \$${amount.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _StatusPill(status: status),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedMoneyProgress(
                value: isPaid ? 1 : progress,
                label: 'Amount paid',
                color: accent,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ActionChipButton(
                    icon: isPaid ? Icons.undo_rounded : Icons.done_all_rounded,
                    label: isPaid ? 'Mark unpaid' : 'Mark paid',
                    color: isPaid ? AppColors.red : AppColors.green,
                    onTap: () async {
                      await ApiService.updateObligation(docId, {
                        'paid': !isPaid ? amount : 0,
                      });
                      await widget.onRefresh();
                    },
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'Edit',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        premiumRoute(
                          Editpage(
                            docId: docId,
                            title: title,
                            category: category,
                            priority: priority,
                            amount: amount.toInt(),
                            paid: paid.toInt(),
                            type: data['type']?.toString() ?? '',
                            date: _parseDate(data['dueDate']),
                            index: widget.index,
                          ),
                        ),
                      );
                      if (result == true) widget.onRefresh();
                    },
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, docId),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete obligation?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ApiService.deleteObligation(docId);
      await widget.onRefresh();
    }
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 22),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.74),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.teal, size: 52),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _PremiumBottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded, 'Home'),
      (Icons.pie_chart_rounded, 'Stats'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepTeal.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.teal.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[index].$1, color: selected ? AppColors.teal : AppColors.muted),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.only(top: 5),
                        width: selected ? 24 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}