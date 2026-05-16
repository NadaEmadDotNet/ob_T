import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddObligationPage extends StatefulWidget {
  const AddObligationPage({super.key});

  @override
  State<AddObligationPage> createState() => _AddObligationPageState();
}

class _AddObligationPageState extends State<AddObligationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  DateTime? selectedDate;
  String? priority;
  String? selectedCategory;

  final List<String> categories = [
    "University",
    "Home",
    "Shopping",
    "Bills",
    "Installments",
    "Other",
  ];

  void autoSetPriority() {
    if (selectedDate == null) return;

    final daysLeft = selectedDate!.difference(DateTime.now()).inDays;

    if (daysLeft <= 3) {
      priority = "High";
    } else if (daysLeft <= 10) {
      priority = "Medium";
    } else {
      priority = "Low";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      
  backgroundColor: const Color(0xFFAEECE4),
  elevation: 0,
  iconTheme: const IconThemeData(color: Color(0xFF0A6A60)),
  title: const Text(
    "+ Add New Obligation",
    style: TextStyle(
      fontSize: 22, 
      fontWeight: FontWeight.bold,
      color: Color(0xff0a6a60),
    ),
  ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAEECE4), Color(0xFFF8EEDC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      

                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        decoration: inputStyle("Title"),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: inputStyle("Amount", prefix: "\$ "),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Required";
                          if (double.tryParse(value) == null) return "Enter valid number";
                          return null;
                        },
                      ),


                      const SizedBox(height: 20),
                      DropdownButtonFormField(
                        decoration: inputStyle("Category"),
                        value: selectedCategory,
                        items: categories
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) => setState(() => selectedCategory = value),
                        validator: (value) => value == null ? "Choose category" : null,
                      ),


                      const SizedBox(height: 20),
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        decoration: inputStyle(
                          "Date",
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Choose date" : null,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            selectedDate = picked;
                            dateController.text =
                                "${picked.day}/${picked.month}/${picked.year}";
                            autoSetPriority();
                          }
                        },
                      ),

                      const SizedBox(height: 20),
                      DropdownButtonFormField(
                        decoration: inputStyle("Priority"),
                        value: priority,
                        items: const [
                          DropdownMenuItem(value: "High", child: Text("High")),
                          DropdownMenuItem(value: "Medium", child: Text("Medium")),
                          DropdownMenuItem(value: "Low", child: Text("Low")),
                        ],
                        onChanged: (value) => setState(() => priority = value),
                        validator: (value) => value == null ? "Choose priority" : null,
                      ),

                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CC7B8),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("User not logged in")),
                              );
                              return;
                            }

                            final double? amount =
                                double.tryParse(amountController.text.trim());
                            if (amount == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Enter valid amount")),
                              );
                              return;
                            }

                            try {
                              await FirebaseFirestore.instance.collection("obligations").add({
                              "title": titleController.text.trim(),
                              "amount": amount,
                              "category": selectedCategory,
                              "date": Timestamp.fromDate(selectedDate!),
                              "priority": priority,
                              "isPaid": false,
                            "userId": user.uid,
                              "paid": 0,
                              "remaining": amount,
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Obligation added successfully"),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              titleController.clear();
                              amountController.clear();
                              dateController.clear();
                              selectedDate = null;
                              selectedCategory = null;
                              priority = null;
                              setState(() {});

                              Future.delayed(const Duration(seconds: 2), () {
                                Navigator.pop(context, true);
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          child: const Text(
                            "Save",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
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

  InputDecoration inputStyle(String label, {String? prefix, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixText: prefix,
      suffixIcon: suffixIcon,
    );
  }
}