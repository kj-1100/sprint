import 'package:flutter/material.dart';


class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final Function(String)? onChanged;
  final Function()? onTap;
  final bool readOnly;

  final Color backgroundColor;

  final TextAlign textAlign;
  final TextInputAction textInputAction;
  
  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText = "Digite aqui",
    this.labelText = "Texto",
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
    this.onTap,
    this.readOnly = false,

    this.backgroundColor = Colors.transparent,

    this.textAlign = TextAlign.start,
    this.textInputAction = TextInputAction.done,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      textAlign: textAlign,
      textInputAction: textInputAction,

      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, ) : null,
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        
        ),
      ),
    );
  }
}