import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/attachment_helper.dart';

class ParentConnectScreen extends StatefulWidget {
  const ParentConnectScreen({super.key});

  @override
  State<ParentConnectScreen> createState() => _ParentConnectScreenState();
}

class _ParentConnectScreenState extends State<ParentConnectScreen> {
  String _searchQuery = '';
  String _newChatSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshBroadcasts();
      appState.loadLiveData();
    });
  }

  void _showNewChatBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredStudents = appState.students.where((s) {
              final q = _newChatSearchQuery.toLowerCase();
              return s.name.toLowerCase().contains(q) ||
                  s.parentName.toLowerCase().contains(q);
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people_outline, color: AppColors.secondary),
                          SizedBox(width: 8),
                          Text(
                            'Start New Conversation',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        _newChatSearchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search student or parent to chat...',
                      fillColor: const Color(0xFFF5F7FA),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // List
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                      minHeight: 150,
                    ),
                    child: filteredStudents.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = filteredStudents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      student.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      (student.rollNo.isNotEmpty && student.rollNo != '1')
                                          ? 'Roll No: ${student.rollNo} • ${student.studentClass}'
                                          : student.studentClass,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            student.parentName,
                                            style: const TextStyle(
                                              color: AppColors.secondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Tap to message parent',
                                          style: TextStyle(fontSize: 8, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // Trigger start new chat
                                      final existing = appState.parentConversations
                                          .where((c) => c.studentName == student.name);
                                      if (existing.isNotEmpty) {
                                        Navigator.pushNamed(context, '/parent-connect/chat/${existing.first.parentId}');
                                        return;
                                      }
                                      
                                      final newParentId = 'P_${DateTime.now().millisecondsSinceEpoch}';
                                      final newConv = ParentConversation(
                                        parentId: newParentId,
                                        parentName: student.parentName.startsWith('Mr.') || student.parentName.startsWith('Mrs.')
                                            ? student.parentName
                                            : 'Mr./Mrs. ${student.parentName}',
                                        studentName: student.name,
                                        studentClass: student.studentClass,
                                        mobile: student.parentMobile,
                                        lastMessage: 'Conversation started',
                                        messages: [],
                                        timeLabel: 'Just now',
                                      );
                                      appState.startNewConversation(newConv);
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Chat started with parent of ${student.name}')),
                                      );
                                      Navigator.pushNamed(context, '/parent-connect/chat/$newParentId');
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.help_outline, color: Colors.grey, size: 32),
                                SizedBox(height: 8),
                                Text(
                                  'No students found matching search',
                                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;
    final isSubjectTeacher = teacher?.designation == 'Subject Teacher';

    if (isSubjectTeacher) {
      return Scaffold(
        body: Column(
          children: [
            // Header
            Container(
              color: AppColors.secondary,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Row(
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
                    appState.translate('parentConnect'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Warning layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.message_outlined,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Parent conversations are managed by the Class Teacher',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Parent conversations are managed by the Class Teacher. For urgent parent communication, please coordinate with the Class Teacher.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    appState.translate('goBackToDashboard'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Class Teacher view
    final conversations = appState.parentConversations.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.parentName.toLowerCase().contains(q) ||
          c.studentName.toLowerCase().contains(q);
    }).toList();

    // Sort: unread/failed first, then custom list index order
    conversations.sort((a, b) {
      final aLatestFailed = a.messages.isNotEmpty && a.messages.last.failed;
      final bLatestFailed = b.messages.isNotEmpty && b.messages.last.failed;
      final aHasBadge = a.unread || aLatestFailed;
      final bHasBadge = b.unread || bLatestFailed;
      if (aHasBadge && !bHasBadge) return -1;
      if (!aHasBadge && bHasBadge) return 1;
      return 0;
    });

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header & Search
              Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
                child: Column(
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
                          appState.translate('parentConnect'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Search Bar
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search by parent or student name',
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Conversations List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await appState.refreshBroadcasts();
                    await appState.loadLiveData();
                  },
                  color: AppColors.secondary,
                  child: conversations.isNotEmpty
                      ? ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final c = conversations[index];
                          final hasFailed = c.messages.isNotEmpty && c.messages.last.failed;
                          final isHighlight = c.unread || hasFailed;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isHighlight ? const Color(0xFFFFFBEB) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isHighlight ? AppColors.secondary.withOpacity(0.2) : Colors.transparent,
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
                                onTap: () => Navigator.pushNamed(context, '/parent-connect/chat/${c.parentId}'),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              c.parentName.replaceAll('Mr. ', '').replaceAll('Mrs. ', '').isNotEmpty
                                                  ? c.parentName.replaceAll('Mr. ', '').replaceAll('Mrs. ', '')[0]
                                                  : 'P',
                                              style: const TextStyle(
                                                color: AppColors.secondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (isHighlight)
                                            Positioned(
                                              top: -2,
                                              right: -2,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    c.parentName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  c.timeLabel ?? 'Recent',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isHighlight ? AppColors.secondary : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Parent of ${c.studentName} • ${c.studentClass}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: hasFailed
                                                      ? const Text(
                                                          '⚠️ Failed to send message',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        )
                                                      : Text(
                                                          c.lastMessage,
                                                          style: TextStyle(
                                                            color: isHighlight ? const Color(0xFF1F2937) : Colors.grey,
                                                            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                                                            fontSize: 12,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                ),
                                                
                                                // Call action
                                                InkWell(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Calling parent at ${c.mobile}...')),
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(15),
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.secondary.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.phone, size: 14, color: AppColors.secondary),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('No conversations found', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap + New Conversation to start a message thread.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
          
          // FAB
          Positioned(
            bottom: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () => _showNewChatBottomSheet(context, appState),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 6,
                shadowColor: AppColors.secondary.withOpacity(0.4),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Conversation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class ParentChatScreen extends StatefulWidget {
  final String parentId;

  const ParentChatScreen({
    super.key,
    required this.parentId,
  });

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachmentOpen = false;

  @override
  void initState() {
    super.initState();
    // Mark conversation read on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.markChatAsRead(widget.parentId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(AppState appState) {
    final text = _msgController.text;
    if (text.trim().isEmpty) return;

    appState.addParentMessage(widget.parentId, text, 'teacher');
    _msgController.clear();
    _scrollToBottom();

    // Trigger retry flow simulation if user typed "fail"
    if (text.toLowerCase().contains('fail')) {
      final conv = appState.parentConversations.firstWhere((c) => c.parentId == widget.parentId);
      if (conv.messages.isNotEmpty) {
        setState(() {
          conv.messages.last.failed = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message transmission failed!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Dynamic parent reply
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        appState.addParentMessage(widget.parentId, 'Okay, thank you for the update! I will coordinate this.', 'parent');
        _scrollToBottom();
      }
    });
  }

  Future<void> _handleAttachCamera(AppState appState) async {
    final result = await AttachmentHelper.pickFromCamera();
    if (result != null) {
      _sendAttachedFile(appState, result.name);
    }
  }

  Future<void> _handleAttachGallery(AppState appState) async {
    final result = await AttachmentHelper.pickFromGallery();
    if (result != null) {
      _sendAttachedFile(appState, result.name);
    }
  }

  Future<void> _handleAttachFileManager(AppState appState) async {
    final result = await AttachmentHelper.pickFromFileManager();
    if (result != null) {
      _sendAttachedFile(appState, result.name);
    }
  }

  void _sendAttachedFile(AppState appState, String fileName) {
    final now = DateTime.now();
    final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

    final newMsg = ParentMessage(
      id: "M_${DateTime.now().millisecondsSinceEpoch}",
      text: fileName,
      sender: 'teacher',
      timestamp: timeStr,
      isAttachment: true,
      attachmentName: fileName,
    );

    appState.addParentMessageObject(widget.parentId, newMsg);
    
    setState(() {
      _isAttachmentOpen = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attached: $fileName')),
    );
    _scrollToBottom();
  }

  void _handleRetrySend(AppState appState, String msgId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retrying message transmission...')),
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        appState.markMessageAsSent(widget.parentId, msgId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!'), backgroundColor: AppColors.success),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final conv = appState.parentConversations.firstWhere(
      (c) => c.parentId == widget.parentId,
      orElse: () => ParentConversation(parentId: '', parentName: 'Unknown', studentName: '', studentClass: '', mobile: '', lastMessage: '', messages: []),
    );

    if (conv.parentId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(appState.translate('noData')),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header Bar
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
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
                    const SizedBox(width: 8),
                    
                    // Avatar bubble
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        conv.parentName.replaceAll('Mr. ', '').replaceAll('Mrs. ', '').isNotEmpty
                            ? conv.parentName.replaceAll('Mr. ', '').replaceAll('Mrs. ', '')[0]
                            : 'P',
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.parentName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${conv.studentName} · ${conv.studentClass}',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Call
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling parent at ${conv.mobile}...')),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: conv.messages.length,
              itemBuilder: (context, index) {
                final msg = conv.messages[index];
                final isTeacher = msg.sender == 'teacher';
                final isFailed = msg.failed;

                if (isFailed) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              border: Border.all(color: Colors.red.shade100),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  msg.text,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg.timestamp,
                                  style: TextStyle(fontSize: 9, color: Colors.red.shade300, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _handleRetrySend(appState, msg.id),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 12, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                  'Failed. Tap to retry',
                                  style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Normal messages
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isTeacher ? AppColors.secondary : Colors.white,
                        borderRadius: isTeacher
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                topRight: Radius.circular(4),
                              )
                            : const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                topLeft: Radius.circular(4),
                              ),
                        border: isTeacher ? null : Border.all(color: const Color(0xFFF3F4F6)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (msg.isAttachment)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 16,
                                    child: Icon(
                                      AttachmentHelper.getFileIcon(msg.attachmentName!),
                                      color: AttachmentHelper.getFileColor(msg.attachmentName!),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.attachmentName!,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text('PDF Document • 1.2 MB', style: TextStyle(color: Colors.white70, fontSize: 8)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: Colors.white, size: 16),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Downloading ${msg.attachmentName}...')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: isTeacher ? Colors.white : const Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg.timestamp,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isTeacher ? Colors.white70 : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isTeacher && index == conv.messages.length - 1) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.done_all, size: 12, color: Colors.blue),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          //Composer bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isAttachmentOpen = true),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.attach_file, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Type a message... (Type 'fail' to test retry)",
                        fillColor: const Color(0xFFF5F7FA),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(appState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(appState),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Attachment modal bottom sheet simulation
          if (_isAttachmentOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isAttachmentOpen = false),
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {}, // consume clicks
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Select Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _isAttachmentOpen = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAttachOption(Icons.camera_alt, 'Camera', 'Take photo using camera', () => _handleAttachCamera(appState)),
                          _buildAttachOption(Icons.image, 'Gallery', 'Upload photo from gallery', () => _handleAttachGallery(appState)),
                          _buildAttachOption(Icons.folder, 'File Manager', 'PDF, docs, or files from device', () => _handleAttachFileManager(appState)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachOption(IconData icon, String title, String desc, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.secondary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      onTap: onTap,
    );
  }
}
class IconDataEx {
  static const IconData volume_up = Icons.volume_up;
}
