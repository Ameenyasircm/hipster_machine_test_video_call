import 'package:flutter/cupertino.dart';

class GradientButton extends StatelessWidget {
  // The function to call when the button is tapped.
  // Should be null to disable the button.
  final VoidCallback? onPressed;

  // The content of the button, typically a Text or Row/SizedBox for a loader.
  final Widget child;

  // Custom colors for the gradient, defaulting to the theme-appropriate colors.
  final List<Color> colors;

  // Height of the button
  final double height;

  // Border radius for the button's corners
  final double borderRadius;

  const GradientButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.colors = const [
      Color(0xFFC04CFF), // A bright purple
      Color(0xFF4C8DFF), // A bright blue
    ],
    this.height = 50.0,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the opacity based on whether the button is enabled (onPressed is not null)
    final double opacity = onPressed == null ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        // Only trigger the press if the onPressed function is provided (not null)
        onTap: onPressed,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Apply the linear gradient background
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            // Optional: Add a subtle shadow
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}