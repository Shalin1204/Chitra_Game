import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RetroPixelBorder — 2px hard neon border, no radius
// ─────────────────────────────────────────────────────────────────────────────
class RetroPixelBorder extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const RetroPixelBorder({
    super.key,
    required this.child,
    this.borderColor = RetroColors.neonGreen,
    this.borderWidth = 2,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        color: RetroColors.panelBg,
        boxShadow: [
          BoxShadow(color: borderColor.withValues(alpha: 0.25), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RetroButton — pixel-perfect button with neon glow on press
// ─────────────────────────────────────────────────────────────────────────────
class RetroButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;
  final bool isDestructive;

  const RetroButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = RetroColors.neonGreen,
    this.fontSize = 10,
    this.isDestructive = false,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? RetroColors.chaosRed : widget.color;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: _pressed ? color.withValues(alpha: 0.15) : RetroColors.darkBg,
          border: Border.all(color: color, width: 2),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(2, 2)),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: widget.fontSize,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ScanlineOverlay — CRT scanline effect layer
// ─────────────────────────────────────────────────────────────────────────────
class ScanlineOverlay extends StatelessWidget {
  final Widget child;

  const ScanlineOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: CustomPaint(
            painter: _ScanlinePainter(),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A000000)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PixelProgressBar — retro loading bar
// ─────────────────────────────────────────────────────────────────────────────
class PixelProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color color;
  final double height;

  const PixelProgressBar({
    super.key,
    required this.value,
    this.color = RetroColors.neonGreen,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        color: RetroColors.panelBg,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RetroTextField — styled text input
// ─────────────────────────────────────────────────────────────────────────────
class RetroTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const RetroTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'PixelifySans',
        fontSize: 16,
        color: RetroColors.lightText,
      ),
      cursorColor: RetroColors.neonGreen,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlowText — text with neon glow shadow
// ─────────────────────────────────────────────────────────────────────────────
class GlowText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;

  const GlowText(
    this.text, {
    super.key,
    this.style,
    this.glowColor = RetroColors.neonGreen,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.displayMedium!;
    return Text(
      text,
      style: base.copyWith(
        shadows: [
          Shadow(color: glowColor, blurRadius: 10),
          Shadow(color: glowColor, blurRadius: 20),
          Shadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PixelDivider — horizontal rule in neon
// ─────────────────────────────────────────────────────────────────────────────
class PixelDivider extends StatelessWidget {
  final Color color;

  const PixelDivider({super.key, this.color = RetroColors.dimGreen});

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, color: color, margin: const EdgeInsets.symmetric(vertical: 8));
  }
}