import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  bool _showPostForm = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _failedToSend = false;
  String? _attachedFile;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _simulateAttachment(String fileName) {
    setState(() {
      _attachedFile = fileName;
    });
    _showSnackBar("Attached: $fileName", AppColors.success);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handlePost(AppState appState) {
    final title = _titleController.text;
    final message = _messageController.text;

    if (title.trim().isEmpty) {
      _showSnackBar(appState.translate('pleaseEnterTitle'), AppColors.destructive);
      return;
    }
    if (message.trim().isEmpty) {
      _showSnackBar(appState.translate('pleaseEnterMessage'), AppColors.destructive);
      return;
    }

    // Dynamic failure simulation trigger
    if (title.toLowerCase().contains('fail') ||
        title.toLowerCase().contains('error') ||
        message.toLowerCase().contains('fail') ||
        message.toLowerCase().contains('error')) {
      setState(() {
        _failedToSend = true;
      });
      _showSnackBar('Transmission failed. Announcement saved to drafts.', AppColors.destructive);
      return;
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

    final newAnn = Announcement(
      id: "A${now.millisecondsSinceEpoch}",
      title: title,
      message: message,
      author: appState.teacher?.name ?? "Teacher",
      authorId: appState.teacher?.id ?? "T001",
      classScope: appState.teacher?.assignedClass ?? "Grade 3-B",
      date: dateStr,
      time: timeStr,
      scope: 'Class',
    );

    appState.addAnnouncement(newAnn);
    _showSnackBar(appState.translate('announcementPosted'), AppColors.success);
    
    // Clear
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _attachedFile = null;
      _showPostForm = false;
      _failedToSend = false;
    });
  }

  void _handleRetry(AppState appState) {
    _showSnackBar('Retrying sending announcement...', AppColors.primary);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _failedToSend = false;
        });
        _handlePost(appState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;
    final isClassTeacher = teacher?.designation == 'Class Teacher';
    final list = appState.announcements;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      appState.translate('announcement'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isClassTeacher)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPostForm = !_showPostForm;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_showPostForm ? Icons.close : Icons.plus_one, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Subject Teacher alert
                if (!isClassTeacher)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFD97706), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.translate('subjectTeacherNote'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appState.translate('contactClassTeacher'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Form Post
                if (_showPostForm && isClassTeacher) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_failedToSend)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade100),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.error_outline, color: Colors.red),
                                title: const Text(
                                  'Failed to send. Draft saved.',
                                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text(
                                  'Tap to retry sending now',
                                  style: TextStyle(color: Colors.red, fontSize: 10),
                                ),
                                onTap: () => _handleRetry(appState),
                              ),
                            ),
                          ),
                          
                        Text(
                          appState.translate('postAnnouncement'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 12),
                        
                        // Audience Chip
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                'Class 8A — All Parents',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          appState.translate('announcementTitle'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: appState.translate('enterTitle'),
                            fillColor: const Color(0xFFF5F7FA),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Message
                        Text(
                          appState.translate('announcementMessage'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: appState.translate('enterMessage'),
                            fillColor: const Color(0xFFF5F7FA),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Attachments Row
                        const Text(
                          'Attachments',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildAttachButton(Icons.camera_alt_outlined, 'Camera', () => _simulateAttachment('captured_photo.jpg')),
                            const SizedBox(width: 8),
                            _buildAttachButton(Icons.image_outlined, 'Gallery', () => _simulateAttachment('gallery_image.png')),
                            const SizedBox(width: 8),
                            _buildAttachButton(Icons.folder_open_outlined, 'File Manager', () => _simulateAttachment('reference_doc.pdf')),
                          ],
                        ),
                        
                        if (_attachedFile != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(_attachedFile!, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _attachedFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        
                        // Submit Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handlePost(appState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(appState.translate('sendAnnouncement'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_titleController.text.isEmpty) {
                                    _showSnackBar(appState.translate('pleaseEnterTitle'), AppColors.destructive);
                                    return;
                                  }
                                  _showSnackBar('Draft saved successfully!', AppColors.success);
                                  setState(() {
                                    _showPostForm = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(appState.translate('saveAsDraft'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => setState(() => _showPostForm = false),
                            child: Text(appState.translate('cancel'), style: const TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Active list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isTeal = index % 2 == 0;
                    final iconBg = isTeal ? AppColors.primary.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1);
                    final iconColor = isTeal ? AppColors.primary : AppColors.secondary;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnouncementDetailScreen(
                                  announcement: item,
                                  themeColor: iconColor,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: iconBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.campaign, color: iconColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(item.author, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              const SizedBox(width: 6),
                                              const Text('•', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.calendar_month, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(item.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.scope == 'Class' && item.classScope != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: Text(
                                      item.classScope!,
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;
  final Color themeColor;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Announcement Details',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeColor, themeColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign, color: Colors.white70, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                announcement.scope.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            announcement.author,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${announcement.date} at ${announcement.time}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Body
                    const Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                    
                    // Class Scope
                    if (announcement.scope == 'Class' && announcement.classScope != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Class',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          announcement.classScope!,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
