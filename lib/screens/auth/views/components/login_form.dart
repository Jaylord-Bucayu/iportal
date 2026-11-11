import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../constants.dart';

/// Input validation helpers
class InputValidators {
  static String? staffIdValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Staff ID is required';
    }
    if (int.tryParse(value) == null) {
      return 'Staff ID must be numeric';
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

/// Clean login form matching Tasktugas design
class LogInForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function(String?) onSavedStaffId;
  final void Function(String?) onSavedPassword;

  const LogInForm({
    super.key,
    required this.formKey,
    required this.onSavedStaffId,
    required this.onSavedPassword,
  });

  @override
  State<LogInForm> createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  bool _obscurePassword = true;

  InputDecoration _fieldDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 14.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      errorStyle: const TextStyle(
        fontSize: 12,
        color: Colors.red,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff ID field
          _fieldLabel('Staff ID'),
          TextFormField(
            onSaved: widget.onSavedStaffId,
            validator: InputValidators.staffIdValidator,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(hintText: 'Enter your staff ID'),
          ),
          const SizedBox(height: 20),

          // Password field
          _fieldLabel('Password'),
          TextFormField(
            onSaved: widget.onSavedPassword,
            validator: InputValidators.passwordValidator,
            obscureText: _obscurePassword,
            obscuringCharacter: '•',
            textInputAction: TextInputAction.done,
            decoration: _fieldDecoration(
              hintText: 'Enter your password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
          ),
        ],
      ),
    );
  }
}