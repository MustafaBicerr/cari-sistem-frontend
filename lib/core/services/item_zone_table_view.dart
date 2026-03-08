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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: color ?? Colors.black87,
          height: 1.25,
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
  final TextInputType? keyboardType;

  const CompactInput({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.highlight = false,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: keyboardType ?? TextInputType.text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.blue, width: 1.2),
          ),
        ),
      ),
    );
  }
}
