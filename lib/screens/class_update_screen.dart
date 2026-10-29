import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/attachment_helper.dart';
import '../services/mobile_compressor.dart';
import '../services/teacher_data_service.dart';
import '../widgets/upload_progress_dialog.dart';

class ClassUpdateScreen extends StatefulWidget {
  const ClassUpdateScreen({super.key});

  @override
  State<ClassUpdateScreen> createState() => _ClassUpdateScreenState();
}

class _ClassUpdateScreenState extends State<ClassUpdateScreen> {
  bool _showPostForm = false;
  String _type = 'Classwork'; // 'Classwork' | 'Homework'
  String _classSection = '';
  String _subject = '';
  final TextEditingController _descriptionController = TextEditingController();
  String _filterType = 'All'; // 'All' | 'Homework' | 'Classwork'
  final List<AttachmentResult> _selectedAttachments = [];
  bool _failedToPost = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).refreshClassUpdates();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
    final description = _descriptionController.text;

    if (_classSection.isEmpty) {
      _showSnackBar('Please select Class & Section', AppColors.destructive);
      return;
    }
    if (_subject.isEmpty) {
      _showSnackBar('Please select Subject', AppColors.destructive);
      return;
    }
    if (description.trim().isEmpty) {
      _showSnackBar(appState.translate('pleaseEnterMessage'), AppColors.destructive);
      return;
    }

    // Dynamic failure simulation trigger
    if (description.toLowerCase().contains('fail') ||
        description.toLowerCase().contains('error')) {
      setState(() {
        _failedToPost = true;
      });
      _showSnackBar('Transmission failed. Update saved to drafts.', AppColors.destructive);
      return;
    }

    final List<Map<String, dynamic>> uploadedAttachmentMeta = [];
    final List<String> attachmentNames = [];

    // Compress & upload attachments with dynamic progress dialog
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
          attachmentNames.add(att.name);

          // 1. Client-side compression (0% - 40% of this file)
          final file = File(att.path);
          final compResult = await MobileCompressor.compressAttachment(
            file,
            onProgress: (p) {
              final overall = (i + (p * 0.4)) / totalFiles;
              progressNotifier.value = overall;
            },
          );

          // 2. Upload compressed file (40% - 100% of this file)
          final uploadRes = await TeacherDataService.uploadAttachment(
            compResult.file,
            onProgress: (sent, total) {
              if (total > 0) {
                final fileP = sent / total;
                final overall = (i + 0.4 + (fileP * 0.6)) / totalFiles;
                progressNotifier.value = overall;
              }
            },
          );

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
    final dueDateTime = now.add(const Duration(days: 2));
    final dueDateStr = "${dueDateTime.year}-${dueDateTime.month.toString().padLeft(2, '0')}-${dueDateTime.day.toString().padLeft(2, '0')}";

    final formattedClassTarget = (_classSection.startsWith('Class ') || _classSection.startsWith('Grade '))
        ? _classSection
        : 'Class $_classSection';

    final newUpdate = ClassUpdate(
      id: "CU${now.millisecondsSinceEpoch}",
      type: _type,
      title: _type == 'Homework' ? '$_subject Homework' : '$_subject Classwork',
      description: description,
      subject: _subject,
      classTarget: formattedClassTarget,
      teacherId: appState.teacher?.id ?? "T001",
      teacherName: appState.teacher?.name ?? "Teacher",
      dueDate: _type == 'Homework' ? dueDateStr : null,
      attachments: attachmentNames.isNotEmpty ? attachmentNames : null,
      date: dateStr,
    );

    await appState.addClassUpdate(
      newUpdate,
      rawAttachments: uploadedAttachmentMeta.isNotEmpty ? uploadedAttachmentMeta : null,
    );

    if (mounted) {
      _showSnackBar(appState.translate('updatePosted'), AppColors.success);

      // Clear
      _descriptionController.clear();
      setState(() {
        _classSection = '';
        _subject = '';
        _selectedAttachments.clear();
        _showPostForm = false;
        _failedToPost = false;
      });
    }
  }

  void _handleRetry(AppState appState) {
    _showSnackBar('Retrying posting update...', AppColors.primary);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _failedToPost = false;
        });
        _handlePost(appState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;

    final List<String> availableClasses = [];
    if (teacher != null) {
      if (teacher.assignedClasses != null && teacher.assignedClasses!.isNotEmpty) {
        for (var c in teacher.assignedClasses!) {
          if (!availableClasses.contains(c)) availableClasses.add(c);
        }
      }
      if (teacher.assignedClass != null && teacher.assignedClass!.isNotEmpty && !availableClasses.contains(teacher.assignedClass)) {
        availableClasses.add(teacher.assignedClass!);
      }
    }
    if (availableClasses.isEmpty) {
      availableClasses.addAll(['Grade 10 A', 'Grade 10 B']);
    }

    final List<String> availableSubjects = [];
    if (teacher != null && teacher.subjects.isNotEmpty) {
      for (var s in teacher.subjects) {
        if (!availableSubjects.contains(s)) availableSubjects.add(s);
      }
    }
    if (availableSubjects.isEmpty) {
      availableSubjects.addAll(['Mathematics', 'Science', 'English']);
    }

    final filteredUpdates = _filterType == 'All'
        ? appState.classUpdates
        : appState.classUpdates.where((u) => u.type == _filterType).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header & Tabs
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Column(
              children: [
                Row(
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
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          appState.translate('classUpdate'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_showPostForm ? Icons.close : Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tabs
                Row(
                  children: ['All', 'Homework', 'Classwork'].map((f) {
                    final isSelected = _filterType == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _filterType = f),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            appState.translate(f.toLowerCase()),
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Content Scroll
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => appState.refreshClassUpdates(),
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                // Post Form
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
                        if (_failedToPost)
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
                                  'Failed to post. Draft saved.',
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
                          appState.translate('postUpdate'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 12),
                        
                        // Type choice (Classwork / Homework)
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _type = 'Classwork'),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _type == 'Classwork' ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    appState.translate('classwork'),
                                    style: TextStyle(
                                      color: _type == 'Classwork' ? Colors.white : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _type = 'Homework'),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _type == 'Homework' ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    appState.translate('homework'),
                                    style: TextStyle(
                                      color: _type == 'Homework' ? Colors.white : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Dropdowns
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Class & Section', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: availableClasses.contains(_classSection) ? _classSection : null,
                                        hint: const Text('Select'),
                                        isExpanded: true,
                                        items: availableClasses.map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c.startsWith('Class ') || c.startsWith('Grade ') ? c : 'Class $c',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _classSection = val ?? ''),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Subject', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: availableSubjects.contains(_subject) ? _subject : null,
                                        hint: const Text('Select'),
                                        isExpanded: true,
                                        items: availableSubjects.map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s, overflow: TextOverflow.ellipsis),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _subject = val ?? ''),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          appState.translate('description'),
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descriptionController,
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
                        
                        // Actions
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
                                child: Text(appState.translate('postUpdate'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() => _showPostForm = false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(appState.translate('cancel'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // List Updates or Empty State
                if (filteredUpdates.isEmpty && !_showPostForm) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_outlined, size: 32, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterType == 'All'
                              ? 'No Class Updates Yet'
                              : 'No $_filterType Updates',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _filterType == 'All'
                              ? 'Share homework assignments, classwork, and study materials with your classes.'
                              : 'No $_filterType entries recorded yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
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
                          label: const Text('Post Class Update', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredUpdates.length,
                  itemBuilder: (context, index) {
                    final item = filteredUpdates[index];
                    final isUnread = !appState.isNoticeRead(item.id);
                    final isHomework = item.type == 'Homework';
                    final iconBg = isHomework ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1);
                    final iconColor = isHomework ? AppColors.secondary : AppColors.primary;

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
                            appState.markClassUpdateAsRead(item.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClassUpdateDetailScreen(
                                  update: item,
                                  themeColor: iconColor,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.menu_book, color: iconColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
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
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: iconBg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            child: Text(
                                              appState.translate(item.type.toLowerCase()),
                                              style: TextStyle(
                                                color: iconColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(item.subject, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          const SizedBox(width: 6),
                                          const Text('•', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.calendar_month, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(item.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.dueDate != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Due: ${item.dueDate}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ],
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

class ClassUpdateDetailScreen extends StatelessWidget {
  final ClassUpdate update;
  final Color themeColor;

  const ClassUpdateDetailScreen({
    super.key,
    required this.update,
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
                Text(
                  '${update.type} Details',
                  style: const TextStyle(
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
                    // Banner Card
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
                              Text(
                                update.type.toUpperCase(),
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
                            update.subject,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            update.classTarget,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            update.teacherName,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      update.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                    
                    // Due Date
                    if (update.dueDate != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        update.dueDate!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                    
                    // Attachments
                    if (update.attachments != null && update.attachments!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Attachments',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: update.attachments!.map((attachment) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AttachmentHelper.getFileColor(attachment).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  AttachmentHelper.getFileIcon(attachment),
                                  color: AttachmentHelper.getFileColor(attachment),
                                ),
                              ),
                              title: Text(
                                attachment,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Downloading $attachment...')),
                                );
                              },
                            ),
                          );
                        }).toList(),
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
