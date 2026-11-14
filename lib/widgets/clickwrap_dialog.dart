import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class ClickwrapDialog extends StatefulWidget {
  final Map<String, dynamic>? activeDocs;
  final String deviceUuid;

  const ClickwrapDialog({
    super.key,
    required this.activeDocs,
    required this.deviceUuid,
  });

  /// Displays the modal bottom sheet in a non-dismissible manner
  static Future<bool> show(
    BuildContext context, {
    required Map<String, dynamic>? activeDocs,
    required String deviceUuid,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClickwrapDialog(
        activeDocs: activeDocs,
        deviceUuid: deviceUuid,
      ),
    );
    return result == true;
  }

  @override
  State<ClickwrapDialog> createState() => _ClickwrapDialogState();
}

class _ClickwrapDialogState extends State<ClickwrapDialog> {
  bool _agreed = true; // Pre-checked for industry-standard 1-tap consent
  bool _isSubmitting = false;

  String _termsText = '';
  String _privacyText = '';
  String _termsVersion = 'v1.0.0';
  String _privacyVersion = 'v1.0.0';
  String _termsSha256 = '';
  String _privacySha256 = '';

  @override
  void initState() {
    super.initState();
    _loadDocumentContent();
  }

  Future<void> _loadDocumentContent() async {
    try {
      final docs = widget.activeDocs;
      final termsDoc = docs?['terms'] as Map<String, dynamic>?;
      final privacyDoc = docs?['privacy'] as Map<String, dynamic>?;

      if (termsDoc != null &&
          termsDoc['contentMarkdown'] != null &&
          termsDoc['contentMarkdown'].toString().trim().isNotEmpty) {
        _termsText = termsDoc['contentMarkdown'].toString();
        _termsVersion = termsDoc['version']?.toString() ?? 'v1.0.0';
        _termsSha256 = termsDoc['contentSha256']?.toString() ?? '';
      } else {
        _termsText = await rootBundle.loadString('assets/legal/terms_v1.md');
      }

      if (privacyDoc != null &&
          privacyDoc['contentMarkdown'] != null &&
          privacyDoc['contentMarkdown'].toString().trim().isNotEmpty) {
        _privacyText = privacyDoc['contentMarkdown'].toString();
        _privacyVersion = privacyDoc['version']?.toString() ?? 'v1.0.0';
        _privacySha256 = privacyDoc['contentSha256']?.toString() ?? '';
      } else {
        _privacyText = await rootBundle.loadString('assets/legal/privacy_v1.md');
      }
    } catch (e) {
      debugPrint('[ClickwrapDialog] Error loading legal documents: $e');
      try {
        _termsText = await rootBundle.loadString('assets/legal/terms_v1.md');
        _privacyText = await rootBundle.loadString('assets/legal/privacy_v1.md');
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _showDocumentViewer(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  content.isNotEmpty ? content : 'Loading document...',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMain,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAgreeAndContinue() async {
    if (!_agreed || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final consents = [
        {
          'documentType': 'terms_of_service',
          'documentVersion': _termsVersion,
          'documentSha256': _termsSha256,
        },
        {
          'documentType': 'privacy_policy',
          'documentVersion': _privacyVersion,
          'documentSha256': _privacySha256,
        },
      ];

      final success = await ApiService.recordLegalConsent(
        consents: consents,
        deviceUuid: widget.deviceUuid,
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to record agreement. Please check connection and try again.',
            ),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ClickwrapDialog] Agreement recording failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Icon & Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Privacy Policy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Please review and accept our agreements',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Summary Points Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _buildSummaryRow(
                  icon: LucideIcons.shield,
                  title: 'Student & Staff Data Protection',
                  desc: 'All academic, attendance, and school records are strictly confidential.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _buildSummaryRow(
                  icon: LucideIcons.messageCircle,
                  title: 'Professional Communication',
                  desc: 'Official platform for school circulars, homework, and parent connect.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _buildSummaryRow(
                  icon: LucideIcons.lock,
                  title: 'Account Security',
                  desc: 'Keep staff credentials safe and promptly report unauthorized use.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Document View Links
          Row(
            children: [
              Expanded(
                child: _buildDocTile(
                  title: 'Terms of Service',
                  version: _termsVersion,
                  icon: LucideIcons.fileText,
                  onTap: () => _showDocumentViewer('Terms of Service', _termsText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDocTile(
                  title: 'Privacy Policy',
                  version: _privacyVersion,
                  icon: LucideIcons.shieldCheck,
                  onTap: () => _showDocumentViewer('Privacy Policy', _privacyText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkbox (Interactive & Pre-Checked)
          InkWell(
            onTap: () {
              setState(() {
                _agreed = !_agreed;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (val) {
                        setState(() {
                          _agreed = val ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the Terms of Service and Privacy Policy',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action Button (Active Immediately)
          ElevatedButton(
            onPressed: _agreed && !_isSubmitting ? _handleAgreeAndContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Agree & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(LucideIcons.check, size: 18),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocTile({
    required String title,
    required String version,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Read full $version',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

