import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';

import 'user.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import 'middle_oval_clipper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both fields")),
      );
      return;
    }

    final hashed = sha256.convert(utf8.encode(password)).toString();
    final box = Hive.box<User>('users');

    User? user;
    for (var u in box.values) {
      if (u.username == username && u.hashedPassword == hashed) {
        user = u;
        break;
      }
    }

    if (user != null) {
      final sessionBox = await Hive.openBox('session');
      await sessionBox.put('loggedInUser', username);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid username or password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
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
            Column(
              children: [
                const SizedBox(height: 180),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 120),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        "Your journey to a better you starts here",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'HappyMonkey',
                          fontSize: fontSize + 2,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          _buildTextField("Username", _usernameController, fontSize),
                          const SizedBox(height: 20),
                          _buildTextField("Password", _passwordController, fontSize, isPassword: true),
                          const SizedBox(height: 10),
                          _buildCustomButton(
                            text: "Remember me",
                            selected: _rememberMe,
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                          ),
                          const SizedBox(height: 15),
                          _buildCustomButton(
                            text: "Log In",
                            onTap: _login,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            child: Text(
                              "Don't have an account? Sign up",
                              style: TextStyle(
                                fontSize: fontSize - 2,
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


  Widget _buildTextField(String label, TextEditingController controller, double fontSize, {bool isPassword = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: fontSize,
          fontFamily: 'HappyMonkey',
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2F36) : Colors.white,
      ),
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'HappyMonkey',
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 200,
      height: 45,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? (isDark ? const Color(0xFF40D404) : const Color(0xFFDBFFCE))
              : (isDark ? const Color(0xFF2C2F36) : const Color(0xFFE8E8E8)),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.black),
          ),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}