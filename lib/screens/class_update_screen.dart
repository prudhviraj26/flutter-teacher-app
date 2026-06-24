import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

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
  String? _attachedFile = 'Chapter5_reference.pdf';
  bool _failedToPost = false;

  @override
  void dispose() {
    _descriptionController.dispose();
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

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final newUpdate = ClassUpdate(
      id: "CU${now.millisecondsSinceEpoch}",
      type: _type,
      title: _type == 'Homework' ? '$_subject Homework' : '$_subject Classwork',
      description: description,
      subject: _subject,
      classTarget: 'Class $_classSection',
      teacherId: appState.teacher?.id ?? "T001",
      teacherName: appState.teacher?.name ?? "Teacher",
      dueDate: _type == 'Homework' ? "2026-06-15" : null,
      attachments: _attachedFile != null ? [_attachedFile!] : null,
      date: dateStr,
    );

    appState.addClassUpdate(newUpdate);
    _showSnackBar(appState.translate('updatePosted'), AppColors.success);

    // Clear
    _descriptionController.clear();
    setState(() {
      _classSection = '';
      _subject = '';
      _attachedFile = 'Chapter5_reference.pdf';
      _showPostForm = false;
      _failedToPost = false;
    });
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
                              color: Colors.white.withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_showPostForm ? Icons.close : Icons.plus_one, color: Colors.white),
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
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
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
            child: ListView(
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
                                    color: _type == 'Classwork' ? AppColors.primary : AppColors.primary.withOpacity(0.1),
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
                                    color: _type == 'Homework' ? AppColors.primary : AppColors.primary.withOpacity(0.1),
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
                                        value: _classSection.isEmpty ? null : _classSection,
                                        hint: const Text('Select'),
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: '7A', child: Text('Class 7A')),
                                          DropdownMenuItem(value: '7B', child: Text('Class 7B')),
                                          DropdownMenuItem(value: '8A', child: Text('Class 8A')),
                                        ],
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
                                        value: _subject.isEmpty ? null : _subject,
                                        hint: const Text('Select'),
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                                          DropdownMenuItem(value: 'Science', child: Text('Science')),
                                          DropdownMenuItem(value: 'English', child: Text('English')),
                                        ],
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
                        
                        // Attachments Row
                        const Text(
                          'Attachments',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildAttachButton(Icons.camera_alt_outlined, 'Camera', () => _simulateAttachment('photo_captured.jpg')),
                            const SizedBox(width: 8),
                            _buildAttachButton(Icons.image_outlined, 'Gallery', () => _simulateAttachment('gallery_attached.png')),
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
                
                // List Updates
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredUpdates.length,
                  itemBuilder: (context, index) {
                    final item = filteredUpdates[index];
                    final isHomework = item.type == 'Homework';
                    final iconBg = isHomework ? AppColors.secondary.withOpacity(0.1) : AppColors.primary.withOpacity(0.1);
                    final iconColor = isHomework ? AppColors.secondary : AppColors.primary;

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
                                            child: Text(
                                              item.title,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
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
                                  color: themeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.insert_drive_file, color: themeColor),
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
