import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:obligation__tracker/pages/Obligation_Screen.dart';

class Editpage extends StatefulWidget {
  final String docId;
  final String title;
  final String category;
  final String priority;
  final int amount;
  final int paid;
  final bool isPaid;
  final String type;
  final Timestamp date; 
  final int index;

  const Editpage({
    super.key,
    required this.docId,
    required this.title,
    required this.category,
    required this.priority,
    required this.amount,
    required this.paid,
    required this.isPaid,
    required this.type,
    required this.date,
    required this.index,
  });

  @override
  State<Editpage> createState() => _EditpageState();
}

class _EditpageState extends State<Editpage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _paidamountController;
  late TextEditingController _duedateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.title);
    _amountController = TextEditingController(text: widget.amount.toString());
    _paidamountController = TextEditingController(text: widget.paid.toString());
    _duedateController =
        TextEditingController(text: widget.date.toDate().toString().split(' ')[0]);
  }

  String calculatePriority(DateTime dueDate) {
    int diffDays = dueDate.difference(DateTime.now()).inDays;
    if (diffDays <= 3) return "High";
    if (diffDays <= 10) return "Medium";
    return "Low";
  }

  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      int amount = int.parse(_amountController.text);
      int paid = int.parse(_paidamountController.text);
      bool calculatedIsPaid = paid == amount;
      DateTime dueDate = DateTime.parse(_duedateController.text);
      String calculatedPriority = calculatePriority(dueDate);
      Timestamp timestamp = Timestamp.fromDate(dueDate);

      await FirebaseFirestore.instance
          .collection('obligations')
          .doc(widget.docId)
          .update({
        'title': _nameController.text,
        'category': widget.category,
        'priority': calculatedPriority,
        'amount': amount,
        'paid': paid,
        'isPaid': calculatedIsPaid,
        'type': widget.type,
        'date': timestamp,
        'index': widget.index,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved Successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ObligationsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFAEECE4), // لون Mint زي AddObligationPage
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0A6A60)), // لون أيقونات متناسق
        title: const Text(
          "Edit Obligation",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A6A60), 
          ),
        ),

      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFAEECE4),
              Color(0xFFF8EEDC),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Name",
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.trim().isEmpty ? "Name is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Amount",
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value!.trim().isEmpty) return "Amount is required";
                            if (double.tryParse(value) == null) return "Enter a valid number";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _paidamountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Paid Amount",
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value!.trim().isEmpty) return "Paid amount is required";
                            double paid = double.tryParse(value) ?? 0;
                            double amount = double.tryParse(_amountController.text) ?? 0;
                            if (paid > amount) return "Paid amount cannot exceed total amount";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _duedateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Due Date",
                            labelStyle: const TextStyle(color: Colors.black),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                color: Colors.black,
                              ),
                              onPressed: () async {
                                DateTime? pickedtime = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(_duedateController.text) ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedtime != null) {
                                  setState(() {
                                    _duedateController.text = pickedtime.toString().split(" ")[0];
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (value) =>
                              value!.trim().isEmpty ? "Due date is required" : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saveData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CC7B8),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}