import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomField extends StatelessWidget {
  final bool isBottomSpace;
  final String hint;
  final String? error;
  final String? suffixText;
  final bool? labelOut;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final Color? fillColor;
  final TextStyle? style;
  final Iterable<String>? autofillHints;
  final FormFieldValidator? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;

  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;

  const CustomField({super.key,required this.validator, required this.hint, this.controller, this.readOnly=false, this.obscureText=false, this.inputFormatters, this.autofillHints, this.keyboardType, this.onChanged, this.suffixIcon, this.maxLines=1, this.error, this.onTap, this.textCapitalization = TextCapitalization.none, this.labelOut=true, this.prefixIcon, this.suffixText, this.style, this.fillColor, this.isBottomSpace = true});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            autofillHints: autofillHints,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            style: style,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26),
              errorText: error,
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              suffixText: suffixText,
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              filled: fillColor != null ? true : null,
              // fillColor: fillColor,
            ),
            onTap: onTap,
            onChanged: onChanged,
            onSaved: (newValue) { },
          ),
          if(isBottomSpace)const SizedBox(height:20)
        ],
      ),
    );
  }
}