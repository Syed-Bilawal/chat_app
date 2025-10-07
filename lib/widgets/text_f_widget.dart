import 'package:flutter/material.dart';

class TextFieldWidget extends StatefulWidget {
  final String label;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextEditingController textEditingController;
  final TextInputType? inputType;

  const TextFieldWidget({
    super.key,
    required this.label,
    required this.textEditingController,
    this.isPassword = false,
    this.validator,
    this.inputType,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  bool obscureText = false;

  @override
  void initState() {
    if (widget.isPassword) {
      obscureText = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: widget.textEditingController,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        labelText: widget.label,
        suffixIcon: widget.isPassword ? buildObscureBtn(context) : null,
        //  errorText: widget.validator != null ? widget.validator!(widget.textEditingController.text) : null,
      ),
      obscureText: obscureText,
      keyboardType: widget.inputType,
      validator: (value) {
        if (widget.inputType == TextInputType.visiblePassword) {
          if (value == null || value.isEmpty) {
            return 'Password length must be greater than 7';
          }
        }
        if (widget.inputType == TextInputType.phone) {
          if (value == null || value.isEmpty) {
            return 'Phone number length must be 12';
          }
        }
        if (widget.inputType == TextInputType.emailAddress) {
          if (value == null || value.isEmpty) {
            return 'Please enter an email address';
          }
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }
        return null;
      },
    );
  }

  Widget buildObscureBtn(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints(),
      onPressed: () {
        setState(() {
          obscureText = !obscureText;
        });
      },
      icon: Icon(
        obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
