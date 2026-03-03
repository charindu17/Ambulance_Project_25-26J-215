import 'package:flutter/material.dart';

/// Acknowledgment type for ambulance alerts
enum AmbulanceAcknowledgmentType {
  seen('SEEN'),
  aware('AWARE'),
  movingAside('MOVING_ASIDE');

  final String value;
  const AmbulanceAcknowledgmentType(this.value);
}

/// A danger-styled alert dialog for displaying ambulance approach notifications.
/// Covers approximately 75% of the screen with emergency styling.
/// Includes action buttons for acknowledgment.
class AmbulanceAlertDialog extends StatelessWidget {
  final String vehicleNumber;
  final int navigationId;
  final String? message;
  final void Function(AmbulanceAcknowledgmentType type)? onAcknowledge;
  final VoidCallback? onDismiss;

  const AmbulanceAlertDialog({
    super.key,
    required this.vehicleNumber,
    required this.navigationId,
    this.message,
    this.onAcknowledge,
    this.onDismiss,
  });

  /// Show the ambulance alert dialog
  static Future<AmbulanceAcknowledgmentType?> show(
    BuildContext context, {
    required String vehicleNumber,
    required int navigationId,
    String? message,
    void Function(AmbulanceAcknowledgmentType type)? onAcknowledge,
    VoidCallback? onDismiss,
  }) {
    return showDialog<AmbulanceAcknowledgmentType>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => AmbulanceAlertDialog(
        vehicleNumber: vehicleNumber,
        navigationId: navigationId,
        message: message,
        onAcknowledge: onAcknowledge,
        onDismiss: onDismiss,
      ),
    );
  }

  void _handleAcknowledgment(
    BuildContext context,
    AmbulanceAcknowledgmentType type,
  ) {
    onAcknowledge?.call(type);
    Navigator.of(context).pop(type);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.75,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD32F2F), // Red 700
                Color(0xFFB71C1C), // Red 900
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
          child: Column(
            children: [
              // Header with ambulance icon
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(21),
                  ),
                ),
                child: Column(
                  children: [
                    // Animated ambulance icon
                    _PulsingAmbulanceIcon(),
                    const SizedBox(height: 16),
                    const Text(
                      'EMERGENCY ALERT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      const Text(
                        'Ambulance Approaching!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Vehicle number badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: Text(
                          vehicleNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Message
                      Text(
                        message ?? 'Please clear the way for the ambulance.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Primary action: I'm Aware
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAcknowledgment(
                          context,
                          AmbulanceAcknowledgmentType.aware,
                        ),
                        icon: const Icon(Icons.check_circle, size: 24),
                        label: const Text(
                          "I'M AWARE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB71C1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary action: Moving Aside
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAcknowledgment(
                          context,
                          AmbulanceAcknowledgmentType.movingAside,
                        ),
                        icon: const Icon(Icons.directions_car, size: 20),
                        label: const Text(
                          'MOVING ASIDE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white70,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing ambulance icon animation
class _PulsingAmbulanceIcon extends StatefulWidget {
  @override
  State<_PulsingAmbulanceIcon> createState() => _PulsingAmbulanceIconState();
}

class _PulsingAmbulanceIconState extends State<_PulsingAmbulanceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _colorAnimation = ColorTween(
      begin: Colors.white.withValues(alpha: 0.15),
      end: Colors.redAccent.withValues(alpha: 0.3),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(
                      alpha: 0.4 * _opacityAnimation.value,
                    ),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        );
      },
    );
  }
}
