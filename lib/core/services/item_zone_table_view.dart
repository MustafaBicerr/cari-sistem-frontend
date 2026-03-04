import 'package:flutter/material.dart';

class HeaderCell extends StatelessWidget {
  final String title;
  final double width;
  final TextAlign align;
  final Color? color;

  const HeaderCell(
    this.title, {
    required this.width,
    this.align = TextAlign.center,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}

class ItemTableCell extends StatelessWidget {
  final double width;
  final Widget child;
  final bool showBorder;

  const ItemTableCell({
    required this.width,
    required this.child,
    this.showBorder = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border:
            showBorder
                ? Border(right: BorderSide(color: Colors.grey.shade300))
                : null,
      ),
      child: child,
    );
  }
}

class CompactInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final bool highlight;

  const CompactInput({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.highlight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
