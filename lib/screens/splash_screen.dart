import '../widgets/clickwrap_dialog.dart';
import '../services/device_info_service.dart';
import '../services/notification_navigation_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/veyho_logo.dart';
import '../constants/colors.dart';
import 'profile_menu_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Stagger animation entry
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });

    // Synchronized auth bootstrap and navigation
    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    final animDelay = Future.delayed(const Duration(milliseconds: 1800));
    final appState = Provider.of<AppState>(context, listen: false);
    final results = await Future.wait([animDelay, appState.bootstrapAuth()]);
    final authResult = results[1] as AuthBootstrapResult;

    if (!mounted) return;

    if (authResult == AuthBootstrapResult.authenticated ||
        authResult == AuthBootstrapResult.offlineAuthenticated) {
      final needsConsent = await appState.checkNeedsLegalAssent();
      if (needsConsent && mounted) {
        final telemetry = await DeviceInfoService.getDeviceTelemetry();
        if (!mounted) return;
        final agreed = await ClickwrapDialog.show(
          context,
          activeDocs: appState.activeLegalDocs,
          deviceUuid: telemetry.deviceUuid,
        );
        if (!agreed) {
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        final termsDoc = appState.activeLegalDocs?['terms'] as Map<String, dynamic>?;
        final privacyDoc = appState.activeLegalDocs?['privacy'] as Map<String, dynamic>?;
        await appState.onLegalConsentAccepted(
          termsVersion: termsDoc?['version']?.toString() ?? 'v1.0.0',
          privacyVersion: privacyDoc?['version']?.toString() ?? 'v1.0.0',
        );
      }

      if (mounted) {
        if (appState.mustChangePassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(isFirstLogin: true),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
          NotificationNavigationService.checkInitialNotification();
          NotificationNavigationService.requestPermissionAndRegister();
        }
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric circles background decor
          Positioned(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.12), width: 1),
              ),
            ),
          ),
          Positioned(
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.06), width: 1),
              ),
            ),
          ),
          
          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 24),
                  
                  // Central Logo
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VeyhoLogo(scale: 1.2),
                        const SizedBox(height: 14),
                        Text(
                          'TECHNOLOGIES',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Spinner and Loading label
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            backgroundColor: Color(0xFFF3F4F6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TEACHER PORTAL',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
