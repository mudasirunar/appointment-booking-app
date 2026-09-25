import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.nextFocusNode,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _displayedError;
  late String _lastText;

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      _lastText = widget.controller.text;
      widget.controller.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (widget.controller.text != _lastText) {
      _lastText = widget.controller.text;
      if (_displayedError != null) {
        setState(() {
          _displayedError = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        FormField<String>(
          initialValue: widget.controller.text,
          validator: (val) {
            if (widget.validator == null) return null;
            final error = widget.validator!(widget.controller.text);
            _displayedError = error;
            return error;
          },
          builder: (FormFieldState<String> field) {
            return TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              maxLines: widget.maxLines,
              enabled: widget.enabled,
              onChanged: (value) {
                field.didChange(value);
                _handleControllerChange();
                widget.onChanged?.call(value);
              },
              onSubmitted: widget.onFieldSubmitted ??
                  (value) {
                    if (widget.nextFocusNode != null) {
                      FocusScope.of(context).requestFocus(widget.nextFocusNode);
                    } else if (widget.textInputAction == TextInputAction.next) {
                      FocusScope.of(context).nextFocus();
                    } else if (widget.textInputAction == TextInputAction.done) {
                      FocusScope.of(context).unfocus();
                    }
                  },
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimaryOf(context),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, size: 20, color: AppTheme.textSecondaryOf(context))
                    : null,
                suffixIcon: widget.suffixIcon,
                errorText: _displayedError,
              ),
            );
          },
        ),
      ],
    );
  }
}
