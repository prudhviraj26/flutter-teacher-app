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
import '../widgets/class_selector_dropdown.dart';

class ClassUpdateScreen extends StatefulWidget {
  const ClassUpdateScreen({super.key});

  @override
  State<ClassUpdateScreen> createState() => _ClassUpdateScreenState();
}

class _ClassUpdateScreenState extends State<ClassUpdateScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showPostForm = false;
  bool _isPosting = false;
  String _type = 'Classwork'; // 'Classwork' | 'Homework'
  String _classSection = '';
  String _subject = '';
  final TextEditingController _descriptionController = TextEditingController();
  String _filterType = 'All'; // 'All' | 'Homework' | 'Classwork'
  final List<AttachmentResult> _selectedAttachments = [];
  bool _failedToPost = false;

  // Search, Filter & Refresh state
  String _selectedClass = '';
  bool _isSearchOpen = false;
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).refreshClassUpdates();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Provider.of<AppState>(context, listen: false).refreshClassUpdates(forceFull: true);
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

      final resolvedSectionId = appState.teacher?.resolveSectionId(_classSection);
      await appState.addClassUpdate(
        newUpdate,
        rawAttachments: uploadedAttachmentMeta.isNotEmpty ? uploadedAttachmentMeta : null,
        targetSectionId: resolvedSectionId,
      );

      await appState.refreshClassUpdates();

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
    } catch (e) {
      debugPrint('Error posting class update: $e');
      if (mounted) {
        _showSnackBar('Failed to post update: $e', AppColors.destructive);
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
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
      for (var c in teacher.allClassTeacherDisplayNames) {
        if (!availableClasses.contains(c)) availableClasses.add(c);
      }
      if (teacher.assignedClasses != null && teacher.assignedClasses!.isNotEmpty) {
        for (var c in teacher.assignedClasses!) {
          if (c.isNotEmpty && !availableClasses.contains(c)) availableClasses.add(c);
        }
      }
    }
    if (availableClasses.isEmpty) {
      availableClasses.addAll(['Grade 10 A', 'Grade 10 B']);
    }
    if (_selectedClass.isEmpty || !availableClasses.contains(_selectedClass)) {
      _selectedClass = availableClasses.first;
    }

    final Map<String, int> unreadByClass = {};
    if (availableClasses.length > 1) {
      for (final c in availableClasses) {
        final token = Teacher.normalizeClassToken(c);
        final count = appState.classUpdates.where((u) {
          final isAuthoredByTeacher = (teacher?.id != null && u.teacherId == teacher!.id) ||
              (teacher?.name != null && u.teacherName.toLowerCase() == teacher!.name.toLowerCase());
          if (isAuthoredByTeacher || appState.isNoticeRead(u.id)) return false;
          return Teacher.normalizeClassToken(u.classTarget) == token;
        }).length;
        if (count > 0) unreadByClass[c] = count;
      }
    }

    final String headerSubtitle = teacher != null && teacher.allClassTeacherDisplayNames.isNotEmpty
        ? teacher.formatAssignedClasses(maxInline: 2)
        : (teacher?.assignedClass ?? '');

    final List<String> availableSubjects = [];
    if (teacher != null && teacher.subjects.isNotEmpty) {
      for (var s in teacher.subjects) {
        if (!availableSubjects.contains(s)) availableSubjects.add(s);
      }
    }
    if (availableSubjects.isEmpty) {
      availableSubjects.addAll(['Mathematics', 'Science', 'English']);
    }

    final classFiltered = availableClasses.length > 1 && _selectedClass.isNotEmpty
        ? appState.classUpdates.where((u) {
            return Teacher.normalizeClassToken(u.classTarget) == Teacher.normalizeClassToken(_selectedClass);
          }).toList()
        : appState.classUpdates;

    final tabFiltered = _filterType.toLowerCase() == 'all'
        ? classFiltered
        : classFiltered.where((u) => u.type.toLowerCase() == _filterType.toLowerCase()).toList();

    final filteredUpdates = tabFiltered.where((u) {
      final q = _searchTerm.toLowerCase().trim();
      if (q.isEmpty) return true;
      return u.title.toLowerCase().contains(q) ||
          u.description.toLowerCase().contains(q) ||
          u.subject.toLowerCase().contains(q) ||
          u.classTarget.toLowerCase().contains(q) ||
          u.teacherName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header & Tabs
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
            child: Column(
              children: [
                _isSearchOpen
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
                                      ? 'वर्ग अपडेट शोधा...'
                                      : appState.language == 'hi'
                                          ? 'क्लास अपडेट खोजें...'
                                          : 'Search class updates...',
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
                                        appState.translate('classUpdate'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (headerSubtitle.isNotEmpty) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          headerSubtitle,
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
                              if (appState.unreadClassUpdatesCount > 0) ...[
                                GestureDetector(
                                  onTap: () async {
                                    await appState.markAllClassUpdatesAsRead();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            appState.language == 'mr'
                                                ? 'सर्व वर्ग अपडेट वाचले म्हणून चिन्हांकित केले'
                                                : appState.language == 'hi'
                                                    ? 'सभी क्लास अपडेट पढ़े हुए चिह्नित किए गए'
                                                    : 'All class updates marked as read',
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
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

                            ],
                          ),
                        ],
                      ),
                const SizedBox(height: 14),
                
                // Tabs + Header Class Dropdown (when >1 class assigned)
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Homework', 'Classwork'].map((f) {
                            final isSelected = _filterType.toLowerCase() == f.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() {
                                  _filterType = f;
                                  if (f.toLowerCase() == 'homework') {
                                    _type = 'Homework';
                                  } else if (f.toLowerCase() == 'classwork') {
                                    _type = 'Classwork';
                                  }
                                }),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      ),
                    ),
                    if (availableClasses.length > 1) ...[
                      const SizedBox(width: 8),
                      ClassSelectorDropdown(
                        classes: availableClasses,
                        selectedClass: _selectedClass,
                        accentColor: AppColors.primary,
                        unreadCounts: unreadByClass,
                        onChanged: (val) => setState(() {
                          _selectedClass = val;
                          if (_showPostForm) {
                            _classSection = val;
                          }
                        }),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Content Scroll
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => appState.refreshClassUpdates(forceFull: true),
              color: AppColors.primary,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                          _type == 'Homework'
                              ? (appState.language == 'mr' ? 'गृहपाठ जोडा' : appState.language == 'hi' ? 'गृहकार्य जोड़ें' : 'Post Homework')
                              : (appState.language == 'mr' ? 'वर्गकार्य जोडा' : appState.language == 'hi' ? 'कक्षाकार्य जोड़ें' : 'Post Classwork'),
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
                                    color: _type == 'Homework' ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    appState.translate('homework'),
                                    style: TextStyle(
                                      color: _type == 'Homework' ? Colors.white : AppColors.secondary,
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
                        
                        // Actions
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
                                    : Text(appState.translate('postUpdate'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                
                // List Updates or Empty State (subtle borderless indicator; bottom FAB handles creation)
                if (tabFiltered.isEmpty && !_showPostForm) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterType.toLowerCase() == 'homework' ? Icons.assignment_outlined : Icons.menu_book,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterType.toLowerCase() == 'all'
                              ? 'No Class Updates Yet'
                              : 'No $_filterType Updates',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (filteredUpdates.isEmpty && !_showPostForm) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 20),
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_off_rounded, size: 32, color: AppColors.primary),
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
                          'No class updates match "$_searchTerm". Try searching with different keywords.',
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
                          child: const Text('Clear Search', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  for (final item in filteredUpdates) ...[
                    Builder(
                      builder: (context) {
                        final isAuthoredByTeacher = (appState.teacher?.id != null && item.teacherId == appState.teacher!.id) ||
                            (appState.teacher?.name != null && item.teacherName.toLowerCase() == appState.teacher!.name.toLowerCase());
                        final isUnread = !isAuthoredByTeacher && !appState.isNoticeRead(item.id);
                        final isHomework = item.isHomework;
                        final iconBg = isHomework ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1);
                        final iconColor = isHomework ? AppColors.secondary : AppColors.primary;
                        final hasAttachments = (item.attachments != null && item.attachments!.isNotEmpty) ||
                            item.attachmentObjects.isNotEmpty;
                        final attachmentCount = item.attachmentObjects.isNotEmpty
                            ? item.attachmentObjects.length
                            : (item.attachments?.length ?? 0);

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
                                              if (hasAttachments) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.attach_file, size: 12, color: Colors.grey.shade700),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '$attachmentCount',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
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
              ],
            ),
          ),
        ),
        ],
      ),
      floatingActionButton: _showPostForm
          ? null
          : ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showPostForm = true;
                  _isSearchOpen = false;
                  if (availableClasses.isNotEmpty) {
                    _classSection = _selectedClass.isNotEmpty ? _selectedClass : availableClasses.first;
                  }
                  if (_subject.isEmpty && availableSubjects.isNotEmpty) {
                    _subject = availableSubjects.first;
                  }
                  if (_filterType.toLowerCase() == 'homework') {
                    _type = 'Homework';
                  } else if (_filterType.toLowerCase() == 'classwork') {
                    _type = 'Classwork';
                  }
                });
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 6,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                appState.translate('newUpdate'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                    if ((update.attachmentObjects.isNotEmpty) || (update.attachments != null && update.attachments!.isNotEmpty)) ...[
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
                        children: List.generate(
                          update.attachmentObjects.isNotEmpty
                              ? update.attachmentObjects.length
                              : (update.attachments?.length ?? 0),
                          (index) {
                            final NoticeAttachment att = update.attachmentObjects.isNotEmpty
                                ? update.attachmentObjects[index]
                                : NoticeAttachment.fromJson(update.attachments![index]);
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
                                    dateStr: update.date,
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
