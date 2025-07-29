import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class NumericSpinner extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final double step;
  final double? min;
  final double? max;
  final int? decimalPlaces;
  final String? Function(String?)? validator;
  final bool isInteger;

  const NumericSpinner({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.step = 1.0,
    this.min,
    this.max,
    this.decimalPlaces,
    this.validator,
    this.isInteger = true,
  });

  @override
  State<NumericSpinner> createState() => _NumericSpinnerState();
}

class _NumericSpinnerState extends State<NumericSpinner> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double get _currentValue {
    final text = widget.controller.text;
    if (text.isEmpty) return widget.min ?? 0;
    return double.tryParse(text) ?? (widget.min ?? 0);
  }

  void _increment() {
    final currentValue = _currentValue;
    final newValue = currentValue + widget.step;
    
    if (widget.max == null || newValue <= widget.max!) {
      _updateValue(newValue);
    }
  }

  void _decrement() {
    final currentValue = _currentValue;
    final newValue = currentValue - widget.step;
    
    if (widget.min == null || newValue >= widget.min!) {
      _updateValue(newValue);
    }
  }

  void _updateValue(double value) {
    String formattedValue;
    if (widget.isInteger) {
      formattedValue = value.round().toString();
    } else {
      final places = widget.decimalPlaces ?? 2;
      formattedValue = value.toStringAsFixed(places);
    }
    
    widget.controller.text = formattedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGray),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.isInteger 
                      ? TextInputType.number 
                      : const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: widget.isInteger
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  validator: widget.validator,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.lightGray),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _increment,
                      child: Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 1,
                      color: AppColors.lightGray,
                    ),
                    InkWell(
                      onTap: _decrement,
                      child: Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
