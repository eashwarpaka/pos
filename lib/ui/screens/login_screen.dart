import 'package:flutter/material.dart';
import 'package:pos_app/services/license_service.dart';
import 'login_table_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    expiryController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final password = passwordController.text.trim();
    final code = codeController.text.trim();
    final expiry = expiryController.text.trim();

    if (password != LicenseService.adminPassword) {
      showError("Invalid Password");
      return;
    }

    if (expiry.isEmpty) {
      showError("Enter Expiry Date");
      return;
    }

    final valid = await LicenseService.verifyLicense(code, expiry);

    if (!valid) {
      showError("Invalid or Expired License");
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginTableScreen()),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28)
                ),
                const SizedBox(width: 12),
                const Text("System Authorization", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white, letterSpacing: 1.1)),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.security, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFF4500)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_person_outlined, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "POS Activation",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                "Authorized access only",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 40),

              _buildField(expiryController, "Expiry Date (YYYY-MM-DD)", Icons.calendar_today),
              const SizedBox(height: 20),
              _buildField(codeController, "License Code", Icons.vpn_key_outlined),
              const SizedBox(height: 20),
              _buildField(passwordController, "Admin Password", Icons.password, obscure: true),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: login,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFF4500)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF4500).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Activate System",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF8C00), size: 20),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
