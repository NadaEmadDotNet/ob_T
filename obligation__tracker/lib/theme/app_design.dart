import 'package:flutter/material.dart';

// --- Colors ---
class AppColors {
  static const Color teal = Color(0xFF0D9488);      // Premium teal
  static const Color deepTeal = Color(0xFF115E59);  // Deep teal
  static const Color aqua = Color(0xFF2DD4BF);      // Bright aqua
  static const Color surface = Color(0xFFF1F5F9);   // Slate surface
  static const Color cream = Color(0xFFFAF8F5);     // Soft cream background
  static const Color ink = Color(0xFF0F172A);       // Dark slate ink
  static const Color muted = Color(0xFF64748B);     // Muted slate
  static const Color orange = Color(0xFFF59E0B);    // Warm orange/amber
  static const Color red = Color(0xFFEF4444);       // Premium red
  static const Color green = Color(0xFF10B981);     // Emerald green
  static const Color yellow = Color(0xFFEAB308);    // Yellow
}

// --- App Data ---
class AppData {
  static const categories = [
    'Bills',
    'Rent',
    'Home',
    'Insurance',
    'Personal',
    'Utilities',
    'Work',
    'Others',
  ];
  static const priorities = ['Low', 'Medium', 'High'];
  static const statuses = ['Paid', 'Unpaid'];
}

// --- App Background ---
class AppBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppBackground({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cream, Color(0xFFF8FAFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

// --- Premium Button ---
class PremiumButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  const PremiumButton({
    super.key,
    required this.child,
    this.onPressed,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        child,
      ],
    );

    final style = ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: AppColors.teal,
      disabledBackgroundColor: AppColors.teal.withOpacity(0.6),
      disabledForegroundColor: Colors.white.withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 4,
      shadowColor: AppColors.teal.withOpacity(0.3),
    );

    Widget btn = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: buttonContent,
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: btn,
      );
    }
    return btn;
  }
}

// --- Premium Route Transition ---
Route<T> premiumRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.05);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      var fadeAnimation = animation.drive(Tween(begin: 0.0, end: 1.0));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

// --- Priority Badge ---
class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// --- Animated Money Progress ---
class AnimatedMoneyProgress extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const AnimatedMoneyProgress({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// --- Skeleton List ---
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surface),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 14, width: 120, color: AppColors.surface),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 80, color: AppColors.surface),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Helper Functions ---

IconData categoryIcon(dynamic category) {
  final cat = category?.toString().toLowerCase();
  switch (cat) {
    case 'bills':
      return Icons.receipt_long_rounded;
    case 'rent':
      return Icons.home_work_rounded;
    case 'home':
      return Icons.cottage_rounded;
    case 'insurance':
      return Icons.security_rounded;
    case 'personal':
      return Icons.person_rounded;
    case 'utilities':
      return Icons.build_rounded;
    case 'work':
      return Icons.work_rounded;
    case 'others':
    default:
      return Icons.more_horiz_rounded;
  }
}

Color priorityColor(dynamic priority) {
  final pr = priority?.toString().toLowerCase();
  switch (pr) {
    case 'high':
    case 'overdue':
      return AppColors.red;
    case 'medium':
      return AppColors.orange;
    case 'low':
    default:
      return AppColors.green;
  }
}

Color statusColor(dynamic status) {
  final st = status?.toString().toLowerCase();
  switch (st) {
    case 'paid':
      return AppColors.green;
    case 'overdue':
      return AppColors.red;
    case 'unpaid':
    default:
      return AppColors.orange;
  }
}

bool obligationIsPaid(dynamic data) {
  if (data is Map) {
    return data['isPaid'] == true || data['status'] == 'paid';
  }
  return false;
}

String obligationStatusLabel(dynamic data) {
  if (data is! Map) return 'Unpaid';
  if (obligationIsPaid(data)) return 'Paid';
  
  final dueDateStr = data['dueDate']?.toString();
  if (dueDateStr != null) {
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate != null && dueDate.isBefore(DateTime.now())) {
      return 'Overdue';
    }
  }
  return 'Unpaid';
}

String? obligationPriority(dynamic data) {
  if (data is! Map) return null;
  final dbPriority = data['priority']?.toString();
  if (dbPriority != null && dbPriority.isNotEmpty) {
    return dbPriority;
  }
  if (obligationIsPaid(data)) return null;
  
  final dueDateStr = data['dueDate']?.toString();
  if (dueDateStr != null) {
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate != null) {
      final difference = dueDate.difference(DateTime.now()).inDays;
      if (difference < 0) return 'Overdue';
      if (difference <= 3) return 'High';
      if (difference <= 7) return 'Medium';
    }
  }
  return 'Low';
}
