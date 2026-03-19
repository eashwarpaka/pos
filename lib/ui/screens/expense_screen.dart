import 'package:flutter/material.dart';
import 'package:pos_app/services/local_db_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final amountController = TextEditingController();
  final descController = TextEditingController();
  String selectedCategory = "Groceries";
  List<Map<String, dynamic>> expenses = [];

  final List<String> expenseCategories = [
    "Groceries",
    "Salary",
    "Rent",
    "Electricity",
    "Maintenance",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await LocalDbService.loadExpenses();
    setState(() => expenses = data);
  }

  Future<void> _addExpense() async {
    final amount = double.tryParse(amountController.text);
    final desc = descController.text.trim();
    if (amount == null || desc.isEmpty) return;

    await LocalDbService.addExpense(amount, desc, selectedCategory);
    amountController.clear();
    descController.clear();
    _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense added successfully"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                const SizedBox(width: 12),
                const Text("Expense Management", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.money_off_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ADD EXPENSE FORM
          Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Record New Expense", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _field("Description", descController, Icons.description_outlined),
                const SizedBox(height: 16),
                _field("Amount (₹)", amountController, Icons.payments_outlined, isNumber: true),
                const SizedBox(height: 16),
                const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: expenseCategories.map((cat) {
                    final selected = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => selectedCategory = cat);
                      },
                      selectedColor: Colors.orange.withOpacity(0.2),
                      labelStyle: TextStyle(color: selected ? Colors.orange : Colors.black87),
                    );
                  }).toList(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text("Save Expense", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // EXPENSE LIST
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Recent Expenses", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: expenses.isEmpty
                        ? Center(child: Text("No expenses recorded yet", style: TextStyle(color: Colors.grey[400])))
                        : ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (_, i) {
                              final e = expenses[i];
                              final dt = DateTime.parse(e['timestamp']);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), shape: BoxShape.circle),
                                      child: const Icon(Icons.arrow_outward, color: Colors.red, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text("${dt.day}/${dt.month} - ${e['category']}", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text("₹${e['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
