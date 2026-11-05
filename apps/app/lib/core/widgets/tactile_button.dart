import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum ButtonVariant {
  primary,
  secondary,
  danger,
  outline,
  ghost,
}

class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final double height;
  final double? width;
  final double depth;
  final EdgeInsetsGeometry padding;

  const TactileButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.height = 48,
    this.width,
    this.depth = 4.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  (Color bg, Color shadow, Color text) _getColors() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return (AppColors.primaryGreen, AppColors.primaryGreenDark, Colors.white);
      case ButtonVariant.secondary:
        return (AppColors.skyBlue, AppColors.skyBlueDark, Colors.white);
      case ButtonVariant.danger:
        return (AppColors.heartRed, AppColors.heartRedDark, Colors.white);
      case ButtonVariant.outline:
        return (Colors.white, AppColors.borderLight, AppColors.textMain);
      case ButtonVariant.ghost:
        return (Colors.transparent, Colors.transparent, AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, shadowColor, textColor) = _getColors();
    final isEnabled = widget.onPressed != null;
    final currentDepth = _isPressed ? 1.0 : widget.depth;
    final topOffset = _isPressed ? widget.depth - 1.0 : 0.0;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(top: topOffset, bottom: widget.depth - currentDepth),
        decoration: BoxDecoration(
          color: isEnabled ? bgColor : AppColors.borderLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.variant != ButtonVariant.ghost && isEnabled
              ? [
                  BoxShadow(
                    color: shadowColor,
                    offset: Offset(0, currentDepth),
                    blurRadius: 0,
                  ),
                ]
              : null,
          border: widget.variant == ButtonVariant.outline
              ? Border.all(color: AppColors.borderLight, width: 2)
              : null,
        ),
        padding: widget.padding,
        alignment: Alignment.center,
        child: DefaultTextStyle(
          style: TextStyle(
            color: isEnabled ? textColor : AppColors.textLight,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
