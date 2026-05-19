import 'package:flutter/material.dart';
import 'package:obligation__tracker/services/api_service.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class Editpage extends StatefulWidget {
  final String docId;
  final String title;
  final String category;
  final String? priority;
  final int amount;
  final int paid;
  final String type;
  final DateTime date;
  final int index;

  const Editpage({
    super.key,
    required this.docId,
    required this.title,
    required this.category,
    required this.priority,
    required this.amount,
    required this.paid,
    required this.type,
    required this.date,
    required this.index,
  });

  @override
  State<Editpage> createState() => _EditpageState();
}

class _EditpageState extends State<Editpage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _paidController;
  late final TextEditingController _dateController;
  late DateTime _dueDate;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.date;
    _category = AppData.categories.contains(widget.category) ? widget.category : 'Others';
    _titleController = TextEditingController(text: widget.title);
    _amountController = TextEditingController(text: widget.amount.toString());
    _paidController = TextEditingController(text: widget.paid.toString());
    _dateController = TextEditingController(text: _formatDate(_dueDate));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paidController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _dateController.text = _formatDate(picked);
    });
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final paid = double.parse(_paidController.text.trim());

    setState(() => _saving = true);
    try {
      await ApiService.updateObligation(widget.docId, {
        'title': _titleController.text.trim(),
        'category': _category,
        'amount': amount,
        'paid': paid,
        'dueDate': _dueDate.toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit obligation', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(18, 96, 18, 20),
        child: SingleChildScrollView(
          child: Hero(
            tag: 'obligation-${widget.docId}',
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: priorityColor(widget.priority).withOpacity(0.14),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.priority != null) ...[
                            PriorityBadge(priority: widget.priority!),
                            const SizedBox(width: 10),
                          ],
                          const Expanded(
                            child: Text(
                              'Displayed from backend',
                              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
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
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: AppData.categories
                            .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                            .toList(),
                        onChanged: (value) => setState(() => _category = value ?? _category),
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
                      TextFormField(
                        controller: _paidController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Paid amount',
                          prefixIcon: Icon(Icons.payments_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Paid amount is required';
                          final paid = double.tryParse(value.trim());
                          final amount = double.tryParse(_amountController.text.trim()) ?? 0;
                          if (paid == null) return 'Enter a valid number';
                          if (paid > amount) return 'Paid cannot exceed amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Due date',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedMoneyProgress(
                        value: (double.tryParse(_amountController.text) ?? 0) > 0
                            ? (double.tryParse(_paidController.text) ?? 0) / (double.tryParse(_amountController.text) ?? 1)
                            : 0,
                        label: 'Payment progress',
                        color: ((double.tryParse(_amountController.text) ?? 0) > 0 &&
                                (double.tryParse(_paidController.text) ?? 0) >= (double.tryParse(_amountController.text) ?? 0))
                            ? AppColors.green
                            : priorityColor(widget.priority),
                      ),
                      const SizedBox(height: 24),
                      PremiumButton(
                        expanded: true,
                        icon: _saving ? null : Icons.save_rounded,
                        onPressed: _saving ? null : _saveData,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save changes'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}