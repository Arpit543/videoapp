import 'package:flutter/material.dart';

class CustomBtn extends StatelessWidget {
  final String name;
  final bool loading;
  final Color? btnColor;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const CustomBtn({
    super.key,
    required this.name,
    this.loading = false,
    required this.onTap,
    this.btnColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 5,
        surfaceTintColor: Colors.transparent,
        shape: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor ?? btnColor ?? const Color(0xff0C82FE))),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 60,
            width: loading ? 60 : MediaQuery.of(context).size.width * 0.95,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: btnColor ?? const Color(0xff0C82FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: loading
                ? CircularProgressIndicator(color: textColor ?? Colors.white)
                : Text(name,maxLines: 1,style: TextStyle(color: textColor ?? Colors.white,fontSize: 20,fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
