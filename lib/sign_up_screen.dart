import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';

import 'user.dart';
import 'login_screen.dart';
import 'middle_oval_clipper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  void _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email address")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    final hashed = sha256.convert(utf8.encode(password)).toString();
    final box = Hive.box<User>('users');

    if (box.values.any((user) => user.username == username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username already exists")),
      );
      return;
    }

    final newUser = User(
      username: username,
      email: email,
      hashedPassword: hashed,
    );

    await box.add(newUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account created! Please log in.")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  bool isUsernameValid() => _usernameController.text.trim().length >= 3;

  bool isEmailValid() {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  bool isPasswordValid() => _passwordController.text.length >= 6;

  bool isConfirmPasswordValid() {
    final confirm = _confirmPasswordController.text;
    final original = _passwordController.text;

    if (confirm.isEmpty || original.isEmpty) return true;
    return confirm == original;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1D22)
          : const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ClipPath(
                clipper: MiddleOvalClipper(),
                child: Container(
                  height: screenHeight * 0.7,
                  width: screenWidth,
                  color: const Color(0xFFA9CE9B),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      "Create your MindShed account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HappyMonkey',
                        fontSize: fontSize + 2,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          _buildValidatedTextField(
                            label: "Username",
                            controller: _usernameController,
                            isValid: isUsernameValid(),
                          ),
                          const SizedBox(height: 20),
                          _buildValidatedTextField(
                            label: "Email",
                            controller: _emailController,
                            isValid: isEmailValid(),
                          ),
                          const SizedBox(height: 20),
                          _buildValidatedTextField(
                            label: "Password",
                            controller: _passwordController,
                            isValid: isPasswordValid(),
                            obscure: _obscurePassword,
                            toggleObscure: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildValidatedTextField(
                            label: "Confirm Password",
                            controller: _confirmPasswordController,
                            isValid: isConfirmPasswordValid(),
                            obscure: _obscureConfirmPassword,
                            toggleObscure: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: 200,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2C2F36)
                                    : const Color(0xFFE8E8E8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(color: Colors.black),
                                ),
                              ),
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: fontSize,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: Text(
                              "Already have an account? Log in",
                              style: TextStyle(
                                fontSize: fontSize * 0.9,
                                color: Colors.black,
                                fontFamily: 'HappyMonkey',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidatedTextField({
    required String label,
    required TextEditingController controller,
    required bool isValid,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getBorderColor() {
      if (controller.text.isEmpty) return Colors.black;
      if (label == "Confirm Password" && _passwordController.text.isEmpty) return Colors.black;
      return isValid ? Colors.green : Colors.red;
    }

    Widget? getSuffixIcon() {
      if (toggleObscure != null) {
        return IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: toggleObscure,
        );
      } else if (controller.text.isEmpty) {
        return null;
      } else {
        return Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
        );
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'HappyMonkey',
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: getBorderColor(), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: getBorderColor(), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: getBorderColor(), width: 2),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2F36) : Colors.white,
          suffixIcon: getSuffixIcon(),
        ),
        style: TextStyle(
          fontFamily: 'HappyMonkey',
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}