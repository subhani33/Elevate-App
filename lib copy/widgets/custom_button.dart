import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final String? iconPath;
  final double? elevation;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry padding;
  
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF6B4EFF),
    this.textColor = Colors.white,
    this.height = 56.0,
    this.borderRadius = 12.0,
    this.isLoading = false,
    this.iconPath,
    this.elevation = 2.0,
    this.gradientColors,
    this.padding = const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation ?? 0.0,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradientColors != null 
              ? LinearGradient(
                  colors: gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradientColors == null ? backgroundColor : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisAlignment: iconPath != null 
                    ? MainAxisAlignment.start 
                    : MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    ),
                  ] else ...[
                    if (iconPath != null) ...[
                      SvgPicture.asset(
                        iconPath!,
                        height: 24.0,
                        width: 24.0,
                      ),
                      const SizedBox(width: 12.0),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: iconPath != null 
                            ? TextAlign.left 
                            : TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback? onPressed;
  final bool isLoading;
  
  const SocialLoginButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.onPressed,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomButton(
        label: 'Continue with $label',
        onPressed: onPressed,
        isLoading: isLoading,
        iconPath: iconPath,
        backgroundColor: Colors.white,
        textColor: Colors.black87,
        borderRadius: 12.0,
        elevation: 1.0,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? iconPath;
  
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.iconPath,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      iconPath: iconPath,
      backgroundColor: const Color(0xFF6B4EFF),
      textColor: Colors.white,
      gradientColors: const [
        Color(0xFF6B4EFF), // Primary purple
        Color(0xFF8067FF), // Lighter purple
      ],
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? iconPath;
  
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.iconPath,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      iconPath: iconPath,
      backgroundColor: Colors.white,
      textColor: const Color(0xFF6B4EFF),
      elevation: 1.0,
    );
  }
} 