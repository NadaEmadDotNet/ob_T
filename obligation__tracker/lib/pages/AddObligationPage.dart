import 'package:flutter/material.dart';
import 'package:obligation__tracker/services/api_service.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class AddObligationPage extends StatefulWidget {
  const AddObligationPage({super.key});

  @override
  State<AddObligationPage> createState() => _AddObligationPageState();
}

class _AddObligationPageState extends State<AddObligationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedCategory;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      _showSnack('Enter a valid amount');
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.createObligation({
        'title': _titleController.text.trim(),
        'amount': amount,
        'category': _selectedCategory,
        'dueDate': _selectedDate!.toIso8601String(),
        'paid': 0,
      });

      if (!mounted) return;
      _showSnack('Obligation added successfully');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('New obligation', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(18, 96, 18, 20),
        child: SingleChildScrollView(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
            ),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.76),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepTeal.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tell us what is due',
                      style: TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Amount is required';
                        if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: AppData.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(categoryIcon(category), size: 18, color: AppColors.teal),
                                  const SizedBox(width: 10),
                                  Text(category),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (value) => value == null ? 'Choose a category' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Due date',
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                        suffixIcon: Icon(Icons.expand_more_rounded),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Choose a due date' : null,
                    ),
                    const SizedBox(height: 24),
                    PremiumButton(
                      expanded: true,
                      icon: _saving ? null : Icons.check_rounded,
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save obligation'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}