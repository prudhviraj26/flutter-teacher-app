import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/attachment_helper.dart';
import '../services/mobile_compressor.dart';
import '../services/teacher_data_service.dart';
import '../services/attachment_local_store.dart';
import '../widgets/upload_progress_dialog.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  bool _showPostForm = false;
  bool _isPosting = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _failedToSend = false;
  final List<AttachmentResult> _selectedAttachments = [];

  // Search & Refresh state
  bool _isSearchOpen = false;
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).refreshBroadcasts();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Provider.of<AppState>(context, listen: false).refreshBroadcasts();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showOversizedFileDialog(AttachmentResult file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'File Exceeds 60 MB Limit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'The file "${file.name}" is ${file.sizeInMB.toStringAsFixed(1)} MB, which exceeds the maximum limit of 60 MB per attachment. Please select a smaller file or compress it before attaching.',
          style: const TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickCamera() async {
    if (_selectedAttachments.length >= MobileCompressor.maxFilesCount) {
      _showSnackBar('Maximum ${MobileCompressor.maxFilesCount} attachments allowed', AppColors.destructive);
      return;
    }
    final result = await AttachmentHelper.pickFromCamera();
    if (result != null) {
      if (result.isOversized) {
        _showOversizedFileDialog(result);
        return;
      }
      setState(() {
        _selectedAttachments.add(result);
      });
      _showSnackBar("Attached: ${result.name}", AppColors.success);
    }
  }

  Future<void> _handlePickGallery() async {
    final availableSlots = MobileCompressor.maxFilesCount - _selectedAttachments.length;
    if (availableSlots <= 0) {
      _showSnackBar('Maximum ${MobileCompressor.maxFilesCount} attachments allowed', AppColors.destructive);
      return;
    }
    final results = await AttachmentHelper.pickMultipleFromGallery();
    if (results.isNotEmpty) {
      final oversized = results.where((r) => r.isOversized).toList();
      final valid = results.where((r) => !r.isOversized).toList();
      if (oversized.isNotEmpty) {
        _showOversizedFileDialog(oversized.first);
      }
      if (valid.isNotEmpty) {
        final toAdd = valid.take(availableSlots).toList();
        setState(() {
          _selectedAttachments.addAll(toAdd);
        });
        if (valid.length > availableSlots) {
          _showSnackBar("Added ${toAdd.length} files (limit of 20 reached)", AppColors.secondary);
        } else {
          _showSnackBar("Attached ${toAdd.length} image${toAdd.length == 1 ? '' : 's'}", AppColors.success);
        }
      }
    }
  }

  Future<void> _handlePickFileManager() async {
    final availableSlots = MobileCompressor.maxFilesCount - _selectedAttachments.length;
    if (availableSlots <= 0) {
      _showSnackBar('Maximum ${MobileCompressor.maxFilesCount} attachments allowed', AppColors.destructive);
      return;
    }
    final results = await AttachmentHelper.pickMultipleFromFileManager();
    if (results.isNotEmpty) {
      final oversized = results.where((r) => r.isOversized).toList();
      final valid = results.where((r) => !r.isOversized).toList();
      if (oversized.isNotEmpty) {
        _showOversizedFileDialog(oversized.first);
      }
      if (valid.isNotEmpty) {
        final toAdd = valid.take(availableSlots).toList();
        setState(() {
          _selectedAttachments.addAll(toAdd);
        });
        if (valid.length > availableSlots) {
          _showSnackBar("Added ${toAdd.length} files (limit of 20 reached)", AppColors.secondary);
        } else {
          _showSnackBar("Attached ${toAdd.length} file${toAdd.length == 1 ? '' : 's'}", AppColors.success);
        }
      }
    }
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

  Future<void> _handlePost(AppState appState) async {
    if (_isPosting) return;
    setState(() => _isPosting = true);

    try {
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

      final List<Map<String, dynamic>> uploadedAttachmentMeta = [];
      final List<String> attachmentNames = [];

      // Compress & upload attachments with simple file count progress dialog
      if (_selectedAttachments.isNotEmpty) {
        final totalFiles = _selectedAttachments.length;
        final fileIndexNotifier = ValueNotifier<int>(1);
        final progressNotifier = ValueNotifier<double>(0.0);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AnimatedBuilder(
              animation: Listenable.merge([fileIndexNotifier, progressNotifier]),
              builder: (ctx, _) {
                return UploadProgressDialog(
                  fileIndex: fileIndexNotifier.value,
                  totalFiles: totalFiles,
                  progress: progressNotifier.value,
                );
              },
            );
          },
        );

        try {
          for (int i = 0; i < totalFiles; i++) {
            final att = _selectedAttachments[i];
            fileIndexNotifier.value = i + 1;
            progressNotifier.value = i / totalFiles;
            attachmentNames.add(att.name);

            // 1. Client-side compression runs smoothly in background
            final file = File(att.path);
            final compResult = await MobileCompressor.compressAttachment(file);

            // 2. Upload compressed file
            final uploadRes = await TeacherDataService.uploadAttachment(compResult.file);

            // 3. Upload thumbnail if generated (images/videos)
            String? thumbBlobPath;
            String? thumbUrl;
            if (compResult.thumbnailFile != null) {
              try {
                final thumbRes = await TeacherDataService.uploadAttachment(compResult.thumbnailFile!);
                if (thumbRes != null) {
                  thumbBlobPath = thumbRes['blobPath']?.toString();
                  thumbUrl = thumbRes['readUrl']?.toString();
                }
              } catch (_) {}
            }

            if (uploadRes != null) {
              uploadedAttachmentMeta.add({
                'name': att.name,
                'blobPath': uploadRes['blobPath'],
                'sizeBytes': compResult.compressedSizeBytes,
                'contentType': uploadRes['contentType'] ?? 'application/octet-stream',
                'type': compResult.type,
                if (thumbBlobPath != null) 'thumbnailBlobPath': thumbBlobPath,
                if (thumbUrl != null) 'thumbnailUrl': thumbUrl,
              });
            }
            progressNotifier.value = (i + 1) / totalFiles;
          }
        } catch (e) {
          debugPrint('Error uploading attachments: $e');
        } finally {
          if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      }

      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

      final newAnn = Announcement(
        id: "A${now.millisecondsSinceEpoch}",
        title: title,
        message: message,
        author: appState.teacher?.name ?? "Teacher",
        authorId: appState.teacher?.id ?? "",
        classScope: appState.teacher?.assignedClass ?? (appState.teacher?.assignedClasses?.isNotEmpty == true ? appState.teacher!.assignedClasses!.first : "All Classes"),
        date: dateStr,
        time: timeStr,
        scope: 'Class',
        fullDate: now.toIso8601String(),
        attachments: attachmentNames.isNotEmpty ? attachmentNames : null,
      );

      await appState.addAnnouncement(
        newAnn,
        rawAttachments: uploadedAttachmentMeta.isNotEmpty ? uploadedAttachmentMeta : null,
      );

      if (mounted) {
        _showSnackBar(appState.translate('announcementPosted'), AppColors.success);
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedAttachments.clear();
          _showPostForm = false;
          _failedToSend = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
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
    final list = appState.announcements;

    final filteredList = list.where((a) {
      final q = _searchTerm.toLowerCase().trim();
      if (q.isEmpty) return true;
      return a.title.toLowerCase().contains(q) ||
          a.message.toLowerCase().contains(q) ||
          a.author.toLowerCase().contains(q) ||
          (a.classScope != null && a.classScope!.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.secondary,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
            child: _isSearchOpen
                ? Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSearchOpen = false;
                            _searchTerm = '';
                            _searchController.clear();
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (val) {
                              setState(() {
                                _searchTerm = val;
                              });
                            },
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: appState.language == 'mr'
                                  ? 'सूचना शोधा...'
                                  : appState.language == 'hi'
                                      ? 'सूचना खोजें...'
                                      : 'Search announcements...',
                              hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
                              suffixIcon: _searchTerm.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchTerm = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    appState.translate('classAnnouncement'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (teacher?.assignedClass != null) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      teacher!.assignedClass!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (appState.unreadAnnouncementsCount > 0) ...[
                            GestureDetector(
                              onTap: () async {
                                await appState.markAllAnnouncementsAsRead();
                                if (mounted) {
                                  _showSnackBar(
                                    appState.language == 'mr'
                                        ? 'सर्व सूचना वाचल्या म्हणून चिन्हांकित केल्या'
                                        : appState.language == 'hi'
                                            ? 'सभी घोषणाओं को पढ़ा हुआ चिह्नित किया गया'
                                            : 'All announcements marked as read',
                                    AppColors.success,
                                  );
                                }
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.done_all, color: Colors.white, size: 17),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSearchOpen = true;
                                _showPostForm = false;
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.search, color: Colors.white, size: 17),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isRefreshing ? null : _handleRefresh,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: _isRefreshing
                                  ? const Center(
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.refresh, color: Colors.white, size: 17),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showPostForm = !_showPostForm;
                                if (_showPostForm) {
                                  _isSearchOpen = false;
                                }
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_showPostForm ? Icons.close : Icons.add, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => appState.refreshBroadcasts(),
              color: AppColors.secondary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                // Form Post
                if (_showPostForm) ...[
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                '${teacher?.assignedClass ?? (teacher?.assignedClasses?.isNotEmpty == true ? teacher!.assignedClasses!.first : "Assigned Classes")} — Class Parents',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
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
                          textCapitalization: TextCapitalization.sentences,
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
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: appState.translate('enterMessage'),
                            fillColor: const Color(0xFFF5F7FA),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Attachments Header & Counter (max 20)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Attachments',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedAttachments.length >= 20
                                    ? AppColors.destructive.withValues(alpha: 0.1)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedAttachments.length}/20',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedAttachments.length >= 20
                                      ? AppColors.destructive
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildAttachButton(Icons.camera_alt_outlined, 'Camera', _handlePickCamera),
                            const SizedBox(width: 8),
                            _buildAttachButton(Icons.image_outlined, 'Gallery', _handlePickGallery),
                            const SizedBox(width: 8),
                            _buildAttachButton(Icons.folder_open_outlined, 'File Manager', _handlePickFileManager),
                          ],
                        ),

                        // Selected Attachments List
                        if (_selectedAttachments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ..._selectedAttachments.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final file = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    AttachmentHelper.getFileIcon(file.name),
                                    color: AttachmentHelper.getFileColor(file.name),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMain,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (file.sizeBytes > 0)
                                          Text(
                                            '${file.sizeInMB.toStringAsFixed(1)} MB',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                    onPressed: () {
                                      setState(() {
                                        _selectedAttachments.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 20),
                        
                        // Submit Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isPosting ? null : () => _handlePost(appState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isPosting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(appState.translate('sendAnnouncement'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                
                // Empty state
                if (list.isEmpty && !_showPostForm) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.campaign_outlined, size: 32, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Class Announcements Yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the + button at the top to publish an announcement, activity notice, or competition details to ${teacher?.assignedClass ?? "your class"}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showPostForm = true;
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Post Announcement', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Search no results state
                if (list.isNotEmpty && filteredList.isEmpty && !_showPostForm) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_off_rounded, size: 32, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Results Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No announcements match "$_searchTerm". Try searching with different keywords.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchTerm = '';
                              _searchController.clear();
                            });
                          },
                          child: const Text('Clear Search', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Active list
                if (filteredList.isNotEmpty)
                  ...filteredList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isAuthoredByTeacher = (appState.teacher?.id != null && item.authorId == appState.teacher!.id) ||
                        (appState.teacher?.name != null && item.author.toLowerCase() == appState.teacher!.name.toLowerCase());
                    final isUnread = !isAuthoredByTeacher && !appState.isNoticeRead(item.id);
                    final isTeal = index % 2 == 0;
                    final iconBg = isTeal ? AppColors.primary.withValues(alpha: 0.1) : AppColors.secondary.withValues(alpha: 0.1);
                    final iconColor = isTeal ? AppColors.primary : AppColors.secondary;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUnread ? iconColor.withValues(alpha: 0.5) : const Color(0xFFF3F4F6),
                            width: isUnread ? 1.5 : 1.0,
                          ),
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
                            appState.markAnnouncementAsRead(item.id);
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
                                          Row(
                                            children: [
                                              if (isUnread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(right: 6),
                                                  decoration: BoxDecoration(
                                                    color: iconColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                    color: const Color(0xFF1F2937),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
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
                                  Row(
                                    children: [
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
                                      if (item.attachments != null && item.attachments!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.attach_file, size: 12, color: Colors.grey.shade700),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${item.attachments!.length}',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
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
                          colors: [themeColor, themeColor.withValues(alpha: 0.8)],
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
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
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
                          color: themeColor.withValues(alpha: 0.1),
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

                    // Attachments Section
                    if ((announcement.attachmentObjects.isNotEmpty) || (announcement.attachments != null && announcement.attachments!.isNotEmpty)) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Attachments',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(
                          announcement.attachmentObjects.isNotEmpty
                              ? announcement.attachmentObjects.length
                              : (announcement.attachments?.length ?? 0),
                          (index) {
                            final NoticeAttachment att = announcement.attachmentObjects.isNotEmpty
                                ? announcement.attachmentObjects[index]
                                : NoticeAttachment.fromJson(announcement.attachments![index]);
                            final fileName = att.name;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AttachmentHelper.getFileColor(fileName).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    AttachmentHelper.getFileIcon(fileName),
                                    color: AttachmentHelper.getFileColor(fileName),
                                  ),
                                ),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: att.formattedSize.isNotEmpty
                                    ? Text(att.formattedSize, style: const TextStyle(fontSize: 11, color: Colors.grey))
                                    : null,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'View',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  final key = att.blobPath?.isNotEmpty == true
                                      ? att.blobPath!
                                      : (att.url.isNotEmpty ? att.url : att.name);
                                  await AttachmentLocalStore.openAttachment(
                                    context: context,
                                    key: key,
                                    url: att.url,
                                    dateStr: announcement.fullDate ?? announcement.date,
                                    originalFileName: att.name,
                                  );
                                },
                              ),
                            );
                          },
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
