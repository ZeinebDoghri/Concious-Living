import 'package:flutter/material.dart';
import '../../theme/role_colors.dart';

/// Standardized text input field
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? labelText;
  final String? errorText;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool isRequired;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? suffixIconOnPressed;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.labelText,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.isRequired = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconOnPressed,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      validator: widget.validator,
      textCapitalization: widget.textCapitalization,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText != null
            ? widget.isRequired
                  ? '${widget.labelText} *'
                  : widget.labelText
            : null,
        errorText: widget.errorText,
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.textSecondary)
            : null,
        suffixIcon: widget.suffixIcon != null
            ? IconButton(
                icon: Icon(widget.suffixIcon, color: AppColors.textSecondary),
                onPressed:
                    widget.suffixIconOnPressed ??
                    () {
                      if (widget.obscureText) {
                        setState(() => _obscureText = !_obscureText);
                      }
                    },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Dropdown field
class AppDropdownField<T> extends StatelessWidget {
  final String labelText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final IconData? prefixIcon;
  final String hintText;
  final bool isRequired;

  const AppDropdownField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.prefixIcon,
    this.hintText = 'Select an option',
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textSecondary)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Search field
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final bool autoFocus;

  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search...',
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autoFocus,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.cardBackground,
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Pill-shaped toggle buttons (for role selector, etc.)
class PillToggle extends StatefulWidget {
  final List<String> options;
  final int initialIndex;
  final ValueChanged<int> onChanged;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  const PillToggle({
    super.key,
    required this.options,
    this.initialIndex = 0,
    required this.onChanged,
    this.selectedColor = AppColors.primary,
    this.unselectedColor = Colors.white,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = AppColors.textSecondary,
  });

  @override
  State<PillToggle> createState() => _PillToggleState();
}

class _PillToggleState extends State<PillToggle> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(widget.options.length, (index) {
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = index);
                widget.onChanged(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.selectedColor
                      : widget.unselectedColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Text(
                  widget.options[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? widget.selectedTextColor
                        : widget.unselectedTextColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
