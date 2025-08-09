import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'user.dart';
import 'package:intl/intl.dart';

class EditDetailsScreen extends StatefulWidget {
  const EditDetailsScreen({super.key});

  @override
  State<EditDetailsScreen> createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends State<EditDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final sessionBox = await Hive.openBox('session');
    final userBox = await Hive.openBox<User>('users');
    final username = sessionBox.get('loggedInUser');

    final user = userBox.values.firstWhere((u) => u.username == username);

    setState(() {
      _currentUser = user;
      _nameController.text = user.username;
      _emailController.text = user.email;
    });
  }

  void _saveChanges() async {
    final form = _formKey.currentState!;
    form.save();

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    final isChangingPassword = oldPassword.isNotEmpty || newPassword.isNotEmpty || confirmPassword.isNotEmpty;

    if (isChangingPassword) {
      if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all password fields")),
        );
        return;
      }

      final hashedOld = sha256.convert(utf8.encode(oldPassword)).toString();
      if (hashedOld != _currentUser.hashedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Old password is incorrect")),
        );
        return;
      }

      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New passwords do not match")),
        );
        return;
      }
    }

    final userBox = await Hive.openBox<User>('users');
    final index = userBox.values.toList().indexOf(_currentUser);

    final newUsername = _nameController.text.trim().isEmpty ? _currentUser.username : _nameController.text.trim();
    final newEmail = _emailController.text.trim().isEmpty ? _currentUser.email : _emailController.text.trim();

    final updatedUser = User(
      username: newUsername,
      email: newEmail,
      hashedPassword: isChangingPassword
          ? sha256.convert(utf8.encode(newPassword)).toString()
          : _currentUser.hashedPassword,
    );

    await userBox.putAt(index, updatedUser);

    final sessionBox = await Hive.openBox('session');
    await sessionBox.put('loggedInUser', newUsername);

    final oldUsername = _currentUser.username;
    if (newUsername != oldUsername) {
      final petBox = await Hive.openBox('petNames');
      final questBox = await Hive.openBox('dailyQuests');
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final existingPetName = petBox.get(oldUsername);
      if (existingPetName != null) {
        await petBox.put(newUsername, existingPetName);
        await petBox.delete(oldUsername);
      }

      final oldQuestData = questBox.get(oldUsername);
      final oldCompletedQuests = questBox.get('completedQuestsFor_${oldUsername}_$today');

      if (oldQuestData != null) {
        await questBox.put(newUsername, oldQuestData);
        await questBox.delete(oldUsername);
      }

      if (oldCompletedQuests != null) {
        await questBox.put('completedQuestsFor_${newUsername}_$today', oldCompletedQuests);
        await questBox.delete('completedQuestsFor_${oldUsername}_$today');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Details updated successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Details',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Username", _nameController, fontSize),
              const SizedBox(height: 16),
              _buildTextField("Email", _emailController, fontSize, inputType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildPasswordField("Old Password", _oldPasswordController, fontSize, _obscureOldPassword, () {
                setState(() => _obscureOldPassword = !_obscureOldPassword);
              }),
              const SizedBox(height: 16),
              _buildPasswordField("New Password", _newPasswordController, fontSize, _obscureNewPassword, () {
                setState(() => _obscureNewPassword = !_obscureNewPassword);
              }),
              const SizedBox(height: 16),
              _buildPasswordField("Confirm New Password", _confirmPasswordController, fontSize, _obscureConfirmPassword, () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              }),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Text("Save", style: TextStyle(fontSize: fontSize, fontFamily: 'HappyMonkey', color: Colors.black)),
                  ),
                 /* ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Text("Cancel", style: TextStyle(fontSize: fontSize, fontFamily: 'HappyMonkey', color: Colors.black)),
                  ),*/
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, double fontSize, {TextInputType inputType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'HappyMonkey', fontSize: fontSize),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2F36) : Colors.green.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      style: TextStyle(
        fontFamily: 'HappyMonkey',
        fontSize: fontSize,
        color: isDark ? Colors.white : Colors.black,
      ),
      validator: (_) => null,
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, double fontSize, bool obscure, VoidCallback toggleObscure) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'HappyMonkey', fontSize: fontSize),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2F36) : Colors.green.shade50,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: toggleObscure,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      style: TextStyle(
        fontFamily: 'HappyMonkey',
        fontSize: fontSize,
        color: isDark ? Colors.white : Colors.black,
      ),
      validator: (_) => null,
    );
  }
}