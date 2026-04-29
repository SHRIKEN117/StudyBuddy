import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

// ── GlassCard ─────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? glowColor;
  final double? width;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.glowColor,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(16.r);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: padding ?? EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: br,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : AppColors.border.withValues(alpha: 0.7),
            width: 1.0,
          ),
          boxShadow: [
            if (glowColor != null)
              BoxShadow(
                color: glowColor!.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── GradientIcon ──────────────────────────────────────────────────────────────

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final double size;
  final double iconSize;

  const GradientIcon({
    super.key,
    required this.icon,
    required this.gradient,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final s = size.r;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(s * 0.27),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize.r),
    );
  }
}

// ── GradientButton ────────────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final LinearGradient gradient;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient = AppGradients.primary,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      height: height.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : AppColors.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white60,
            disabledBackgroundColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
            textStyle:
                GoogleFonts.ubuntu(fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
          child: loading
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18.r),
                      SizedBox(width: 8.w),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── AppButton ─────────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outline = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 20.r,
            height: 20.r,
            child: const CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18.r),
                SizedBox(width: 8.w),
              ],
              Text(label),
            ],
          );

    if (outline) {
      return OutlinedButton(
          onPressed: loading ? null : onPressed, child: child);
    }

    if (color == null && !loading && onPressed != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.42),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
            textStyle:
                GoogleFonts.ubuntu(fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
          child: child,
        ),
      );
    }

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r)),
        textStyle:
            GoogleFonts.ubuntu(fontSize: 15.sp, fontWeight: FontWeight.w700),
      ),
      child: child,
    );
  }
}

// ── AppTextField ──────────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: context.cTextPrimary,
        fontSize: 15.sp,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
      ),
    );
  }
}

// ── SectionHeader ─────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null)
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

// ── EmptyState ────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GradientIcon(
              icon: icon,
              gradient: AppGradients.primary,
              size: 72,
              iconSize: 32,
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.cTextSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: 28.h),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── StatusBadge ───────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'ready':
        color = AppColors.success;
        label = 'Ready';
      case 'processing':
        color = AppColors.warning;
        label = 'Processing';
      case 'failed':
        color = AppColors.error;
        label = 'Failed';
      default:
        color = context.cTextSecondary;
        label = status;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
