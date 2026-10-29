import 'package:flutter/material.dart';
import '../constants/colors.dart';

class UploadProgressDialog extends StatelessWidget {
  final int fileIndex;
  final int totalFiles;
  final double progress; // 0.0 to 1.0

  const UploadProgressDialog({
    super.key,
    required this.fileIndex,
    required this.totalFiles,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final int percent = (progress.clamp(0.0, 1.0) * 100).round();
    final int currentFile = fileIndex > totalFiles ? totalFiles : (fileIndex < 1 ? 1 : fileIndex);

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cloud Upload Indicator Icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.primaryTeal,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Uploading Attachments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),

              // Dynamic Numerical Progress: File 2 of 4 • 65%
              Text(
                'File $currentFile of $totalFiles • $percent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 14),

              // Smooth Animated LinearProgressIndicator with Rounded Ends
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Footer reassurance
              const Text(
                'Please keep the app open while upload is in progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
