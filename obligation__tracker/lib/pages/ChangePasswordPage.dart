import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final Color gradientTop = const Color(0xFFAEECE2);
  final Color gradientBottom = const Color(0xFFF9F7E8);
  final Color primaryTextColor = const Color(0xFF4B4532);

  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  
  String? _validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must contain letters and numbers';
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        User? user = FirebaseAuth.instance.currentUser;
        
        if (user != null) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _oldPasswordController.text,
          );

          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_newPasswordController.text);

          Navigator.pop(context); 

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password changed successfully!'),
              backgroundColor: primaryTextColor,
            ),
          );

          Navigator.pop(context); 
        }
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        String errorMsg = "An error occurred";
        if (e.code == 'wrong-password') {
          errorMsg = "كلمة المرور الحالية غير صحيحة";
        } else if (e.code == 'weak-password') {
          errorMsg = "كلمة المرور الجديدة ضعيفة جداً";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error! Try again")),
        );
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isObscure,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        validator: validator,
        style: TextStyle(color: primaryTextColor),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryTextColor.withOpacity(0.5)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: primaryTextColor.withOpacity(0.6),
            ),
            onPressed: toggleObscure,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientTop, gradientBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      
                      _buildPasswordField(
                        controller: _oldPasswordController,
                        labelText: 'Current Password',
                        isObscure: _isObscureOld,
                        toggleObscure: () => setState(() => _isObscureOld = !_isObscureOld),
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter current password' : null,
                      ),
                      
                      _buildPasswordField(
                        controller: _newPasswordController,
                        labelText: 'New Password',
                        isObscure: _isObscureNew,
                        toggleObscure: () => setState(() => _isObscureNew = !_isObscureNew),
                        validator: _validatePasswordStrength,
                      ),
                      
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm New Password',
                        isObscure: _isObscureConfirm,
                        toggleObscure: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                        validator: (value) {
                          
                          final strengthError = _validatePasswordStrength(value);
                          if (strengthError != null) return strengthError;
                          
                          
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match!';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: const Color(0xFF81D4FA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}