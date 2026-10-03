import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../widgets/veyho_logo.dart';
import 'profile_menu_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context, AppState appState) async {
    if (_isLoading) return;

    final mobile = _mobileController.text;
    final password = _passwordController.text;

    if (mobile.length != 10) {
      _showToast(context, appState.translate("pleaseEnterValidMobile"));
      return;
    }
    if (password.length < 4) {
      _showToast(context, appState.translate("pleaseEnterPassword"));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await appState.login(mobile, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success) {
      if (context.mounted) {
        if (appState.mustChangePassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(isFirstLogin: true),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } else {
      if (context.mounted) {
        _showToast(context, "Invalid Mobile Number or Password");
      }
    }
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        backgroundColor: AppColors.destructive,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String orgName = appState.language == 'mr'
        ? 'वेहो टेक्नॉलॉजीज'
        : appState.language == 'hi'
            ? 'वेहो टेक्नोलॉजीज'
            : 'Veyho';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Illustration Area
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AspectRatio(
                    aspectRatio: 400 / 240,
                    child: CustomPaint(
                      painter: LoginIllustrationPainter(),
                    ),
                  ),
                ),
              ),
            ),
            
            // Login Card (Fixed width max-w-[480] handled implicitly by mobile layout)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  )
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    orgName,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.translate("teacherPortal"),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Mobile Input
                  Text(
                    appState.translate("mobileNumber"),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_android, color: Colors.grey),
                      hintText: appState.translate("enterMobileNumber"),
                      counterText: "",
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFFF5F7FA),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Input
                  Text(
                    appState.translate("password"),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      hintText: appState.translate("enterPassword"),
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFFF5F7FA),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleLogin(context, appState),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.secondary,
                      elevation: 4,
                      shadowColor: AppColors.secondary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            appState.translate("login"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  
                  // Forgot Password Button
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      appState.translate("forgotPassword"),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Language Switcher Chips
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLangChip(context, appState, 'en', 'English'),
                      const SizedBox(width: 8),
                      _buildLangChip(context, appState, 'hi', 'हिंदी'),
                      const SizedBox(width: 8),
                      _buildLangChip(context, appState, 'mr', 'मराठी'),
                    ],
                  ),
                  
                  // Veyho Branding
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  const VeyhoLogo(scale: 0.6),
                  const SizedBox(height: 6),
                  Text(
                    appState.language == 'mr'
                        ? 'वेहो टेक्नॉलॉजीज'
                        : appState.language == 'hi'
                            ? 'वेहो टेक्नोलॉजीज'
                            : 'Veyho Technologies',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(BuildContext context, AppState appState, String code, String label) {
    final bool isSelected = appState.language == code;
    return InkWell(
      onTap: () => appState.setLanguage(code),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class LoginIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Backdrop shapes
    final whitePaint30 = Paint()..color = Colors.white.withOpacity(0.3);
    final orangePaint = Paint()..color = AppColors.secondary;
    final whitePaint = Paint()..color = Colors.white;
    final tealPaint20 = Paint()..color = AppColors.primary.withOpacity(0.2);

    // Circles
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.25), 20, whitePaint30);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.33), 15, whitePaint30);

    // Floating note rect
    final noteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.2, 40, 30),
      const Radius.circular(4),
    );
    canvas.drawRRect(noteRect, orangePaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.71, size.height * 0.22, 30, 2), whitePaint30);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.71, size.height * 0.25, 30, 2), whitePaint30);

    // Center school desk block
    final deskRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.42, 100, 80),
      const Radius.circular(8),
    );
    canvas.drawRRect(deskRect, whitePaint);
    
    // Draw table details
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.4, size.height * 0.46, 25, 25), const Radius.circular(4)), tealPaint20);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.49, size.height * 0.46, 25, 25), const Radius.circular(4)), tealPaint20);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.58, size.height * 0.46, 10, 25), const Radius.circular(2)), tealPaint20);

    // Small orange box
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.46, size.height * 0.6, 30, 35), const Radius.circular(4)), orangePaint);
    canvas.drawCircle(Offset(size.width * 0.49, size.height * 0.68), 2, whitePaint);

    // Draw school children faces/bodies
    final facePaint1 = Paint()..color = const Color(0xFFFFD4A3);
    final facePaint2 = Paint()..color = const Color(0xFFF4C2A1);
    final facePaint3 = Paint()..color = const Color(0xFFC9976B);
    final bluePaint = Paint()..color = const Color(0xFF3B82F6);

    // Student 1 (Left)
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.58), 15, facePaint1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.65, 24, 30), const Radius.circular(6)), orangePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.25, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);

    // Student 2
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.58), 15, facePaint2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.32, size.height * 0.65, 24, 30), const Radius.circular(6)), orangePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.32, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.35, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);

    // Student 3 (Right)
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.58), 15, facePaint1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.65, size.height * 0.65, 24, 30), const Radius.circular(6)), orangePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.65, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.68, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);

    // Student 4
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.58), 15, facePaint3);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.75, size.height * 0.65, 24, 30), const Radius.circular(6)), orangePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.75, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.78, size.height * 0.77, 10, 20), const Radius.circular(2)), bluePaint);

    // Bottom desk shadow
    final shadowDesk = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.85, size.width, 35),
      const Radius.circular(20),
    );
    canvas.drawRRect(shadowDesk, whitePaint30);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
