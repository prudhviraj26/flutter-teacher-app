import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/attachment_helper.dart';
import '../services/notification_navigation_service.dart';

String _cleanParentName(String name) {
  return name.replaceFirst(RegExp(r'^(Mr\.|Mrs\.|Ms\.|Mr|Mrs|Ms)\s*', caseSensitive: false), '').trim();
}

class ParentConnectScreen extends StatefulWidget {
  const ParentConnectScreen({super.key});

  @override
  State<ParentConnectScreen> createState() => _ParentConnectScreenState();
}

class _ParentConnectScreenState extends State<ParentConnectScreen> {
  String _searchQuery = '';
  String _newChatSearchQuery = '';
  String _activeFilter = 'all'; // 'all' or 'unread'
  Timer? _threadsPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshBroadcasts();
      appState.loadLiveData();
    });
    // Smart auto-polling: refresh conversation list every 8 seconds while screen is open
    _threadsPollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.fetchParentConversations();
      }
    });
  }

  @override
  void dispose() {
    _threadsPollingTimer?.cancel();
    super.dispose();
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
              final q = _newChatSearchQuery.toLowerCase().trim();
              final qNorm = Teacher.normalizeClassToken(q);
              return s.name.toLowerCase().contains(q) ||
                  s.parentName.toLowerCase().contains(q) ||
                  s.studentClass.toLowerCase().contains(q) ||
                  (qNorm.isNotEmpty && Teacher.normalizeClassToken(s.studentClass).contains(qNorm));
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
                      hintText: 'Search student, parent, or class...',
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
                                            color: AppColors.secondary.withValues(alpha: 0.1),
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
                                    onTap: () async {
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(context);
                                      navigator.pop();
                                      final conv = await appState.openOrCreateParentChat(student);
                                      final targetId = (conv.threadId != null && conv.threadId!.isNotEmpty)
                                          ? conv.threadId!
                                          : conv.parentId;
                                      NotificationNavigationService.activeChatParentId = conv.parentId;
                                      NotificationNavigationService.activeChatThreadId = conv.threadId ?? conv.parentId;
                                      if (conv.messages.isEmpty) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Chat opened with parent of ${student.name}')),
                                        );
                                      }
                                      navigator.pushNamed('/parent-connect/chat/$targetId').then((_) {
                                        appState.fetchParentConversations();
                                      });
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

  String _formatConvTimeLabel(ParentConversation c) {
    if (c.timeLabel == 'Just now') return 'Just now';
    final dt = c.lastMessageAt;
    if (dt == null) return c.timeLabel ?? 'Recent';
    final localDt = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(localDt.year, localDt.month, localDt.day);
    final diffDays = today.difference(msgDate).inDays;

    if (diffDays == 0) {
      final hour12 = localDt.hour == 0 ? 12 : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
      final period = localDt.hour >= 12 ? 'PM' : 'AM';
      return "$hour12:${localDt.minute.toString().padLeft(2, '0')} $period";
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (localDt.year == now.year) {
      return "${localDt.day}/${localDt.month}";
    }
    return "${localDt.day}/${localDt.month}/${localDt.year}";
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                        color: AppColors.primary.withValues(alpha: 0.1),
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
    final activeConversations = appState.parentConversations.where((c) {
      return c.messages.isNotEmpty || c.lastMessage.trim().isNotEmpty;
    }).toList();

    final unreadTotal = activeConversations.where((c) => c.unreadCount > 0 || c.unread).length;

    final conversations = activeConversations.where((c) {
      final q = _searchQuery.toLowerCase().trim();
      final qNorm = Teacher.normalizeClassToken(q);
      final matchesSearch = q.isEmpty ||
          c.parentName.toLowerCase().contains(q) ||
          c.studentName.toLowerCase().contains(q) ||
          c.studentClass.toLowerCase().contains(q) ||
          (qNorm.isNotEmpty && Teacher.normalizeClassToken(c.studentClass).contains(qNorm));
      if (!matchesSearch) return false;
      if (_activeFilter == 'unread') {
        return c.unreadCount > 0 || c.unread;
      }
      return true;
    }).toList();

    // Sort strictly descending by lastMessageAt
    conversations.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      body: Column(
            children: [
              // Header & Search
              Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
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
                              color: Colors.white.withValues(alpha: 0.2),
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
                        hintText: 'Search by parent, student, or class',
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips: All & Unread
                    Row(
                      children: [
                        _buildFilterChip(
                          label: 'All',
                          count: activeConversations.length,
                          isSelected: _activeFilter == 'all',
                          onTap: () => setState(() => _activeFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Unread',
                          count: unreadTotal,
                          isSelected: _activeFilter == 'unread',
                          showCountBadge: true,
                          onTap: () => setState(() => _activeFilter = 'unread'),
                        ),
                      ],
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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final c = conversations[index];
                          final hasFailed = c.messages.isNotEmpty && c.messages.last.failed;
                          final isUnread = c.unreadCount > 0 || c.unread;
                          final isHighlight = isUnread || hasFailed;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isHighlight ? const Color(0xFFFFFBEB) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isHighlight ? AppColors.secondary.withValues(alpha: 0.35) : Colors.transparent,
                                  width: isHighlight ? 1.5 : 1,
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
                                onTap: () async {
                                  appState.markChatAsRead(c.parentId);
                                  await Navigator.pushNamed(context, '/parent-connect/chat/${c.parentId}');
                                  if (context.mounted) {
                                    appState.markChatAsRead(c.parentId);
                                    appState.fetchParentConversations();
                                  }
                                },
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
                                              color: AppColors.secondary.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              _cleanParentName(c.parentName).isNotEmpty
                                                  ? _cleanParentName(c.parentName)[0]
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
                                                    _cleanParentName(c.parentName),
                                                    style: TextStyle(
                                                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                                                      fontSize: 14,
                                                      color: const Color(0xFF1F2937),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      _formatConvTimeLabel(c),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isHighlight ? AppColors.secondary : Colors.grey,
                                                      ),
                                                    ),
                                                    if (c.unreadCount > 0)
                                                      Container(
                                                        margin: const EdgeInsets.only(top: 4),
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.secondary,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          '${c.unreadCount} new',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
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
                                                      color: AppColors.secondary.withValues(alpha: 0.1),
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
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => _showNewChatBottomSheet(context, appState),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 6,
          shadowColor: AppColors.secondary.withValues(alpha: 0.4),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Conversation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    bool showCountBadge = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.secondary : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (showCountBadge && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
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

class _ParentChatScreenState extends State<ParentChatScreen> with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _pollingTimer;
  AppState? _appState;
  double _previousBottomInset = 0.0;
  bool _showScrollToBottom = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = Provider.of<AppState>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Track active chat synchronously so polling timers do not evict newly started empty threads
    NotificationNavigationService.activeChatParentId = widget.parentId;
    NotificationNavigationService.activeChatThreadId = widget.parentId;

    // Track scroll position to show/hide "scroll to latest" button
    _scrollController.addListener(_onScrollChanged);

    // Mark conversation read on enter & fetch initial messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      ParentConversation? conv;
      for (final c in appState.parentConversations) {
        if (c.parentId == widget.parentId || c.threadId == widget.parentId) {
          conv = c;
          break;
        }
      }
      NotificationNavigationService.activeChatParentId = conv?.parentId ?? widget.parentId;
      NotificationNavigationService.activeChatThreadId = conv?.threadId ?? widget.parentId;
      appState.markChatAsRead(widget.parentId);
      appState.fetchTeacherThreadMessages(widget.parentId);
    });

    // Auto-scroll to latest message when keyboard pops up if user is near bottom
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _scrollController.hasClients && _scrollController.offset < 200) {
        _scrollToBottom(delayMs: 100);
      }
    });

    _msgController.addListener(() {
      if (mounted) setState(() {});
    });

    _startPolling();
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 250;
    if (show != _showScrollToBottom && mounted) {
      setState(() {
        _showScrollToBottom = show;
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.pollTeacherChatDelta(widget.parentId);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationNavigationService.activeChatThreadId = null;
    NotificationNavigationService.activeChatParentId = null;
    _pollingTimer?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _appState?.markChatAsRead(widget.parentId);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset > _previousBottomInset && bottomInset > 100) {
      // Virtual keyboard expanded: keep latest message in view if user was near bottom
      if (_scrollController.hasClients && _scrollController.offset < 200) {
        _scrollToBottom(delayMs: 100);
      }
    }
    _previousBottomInset = bottomInset;
  }

  void _scrollToBottom({int delayMs = 0}) {
    void execute() {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
      );
    }

    if (delayMs > 0) {
      Timer(Duration(milliseconds: delayMs), execute);
    } else {
      execute();
    }
  }

  void _sendMessage(AppState appState) {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot exceed 1000 characters')),
      );
      return;
    }

    appState.addParentMessage(widget.parentId, text, 'teacher');
    _msgController.clear();
    _scrollToBottom();
  }

  void _confirmDeleteMessage(AppState appState, ParentMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to delete this message? This will delete the message for everyone in this conversation.',
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.deleteTeacherMessage(widget.parentId, msg.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete for Everyone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  DateTime? _parseMessageDate(String ts) {
    if (ts.isEmpty) return null;
    try {
      return DateTime.parse(ts).toLocal();
    } catch (_) {
      return null;
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(msgDate).inDays;

    String text;
    if (diffDays == 0) {
      text = 'Today';
    } else if (diffDays == 1) {
      text = 'Yesterday';
    } else if (date.year == now.year) {
      text = DateFormat('d MMMM').format(date);
    } else {
      text = DateFormat('d MMMM yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  String _formatMsgTime(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return "$hour12:${dt.minute.toString().padLeft(2, '0')} $period";
    } catch (_) {
      return ts;
    }
  }

  Widget _buildTickIcon(ParentMessage msg) {
    if (msg.isRead) {
      return const Icon(
        Icons.done_all,
        size: 13,
        color: Color(0xFF0284C7), // WhatsApp Sky Blue Read tick
      );
    }
    if (msg.status == 'delivered') {
      return const Icon(
        Icons.done_all,
        size: 13,
        color: Colors.white70,
      );
    }
    return Icon(
      msg.status == 'sending' ? Icons.access_time : Icons.done,
      size: 13,
      color: Colors.white70,
    );
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
      (c) => c.parentId == widget.parentId || c.threadId == widget.parentId,
      orElse: () => ParentConversation(parentId: '', parentName: 'Unknown', studentName: '', studentClass: '', mobile: '', lastMessage: '', messages: []),
    );

    if (conv.parentId.isEmpty && conv.studentName.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: const Text('Parent Chat'),
        ),
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                        _cleanParentName(conv.parentName).isNotEmpty
                            ? _cleanParentName(conv.parentName)[0]
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
                          _cleanParentName(conv.parentName),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${conv.studentName} · ${conv.studentClass}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: conv.messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Send a message below to start chatting with ${_cleanParentName(conv.parentName)}.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: conv.messages.length,
                    itemBuilder: (context, index) {
                      final k = conv.messages.length - 1 - index;
                      final msg = conv.messages[k];
                      final isTeacher = msg.sender == 'teacher';
                      final isFailed = msg.failed;

                      final currDate = _parseMessageDate(msg.timestamp);
                      bool showDateSeparator = false;
                      if (currDate != null) {
                        if (k == 0) {
                          showDateSeparator = true;
                        } else {
                          final prevDate = _parseMessageDate(conv.messages[k - 1].timestamp);
                          if (prevDate == null ||
                              prevDate.year != currDate.year ||
                              prevDate.month != currDate.month ||
                              prevDate.day != currDate.day) {
                            showDateSeparator = true;
                          }
                        }
                      }

                Widget bubble;
                if (isFailed) {
                  bubble = Padding(
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
                                  _formatMsgTime(msg.timestamp),
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
                } else if (msg.isDeleted) {
                  bubble = Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'This message was deleted',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatMsgTime(msg.timestamp),
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Normal messages
                  bubble = Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: (!msg.isDeleted && isTeacher)
                          ? () => _confirmDeleteMessage(appState, msg)
                          : null,
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
                                  color: Colors.black.withValues(alpha: 0.12),
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
                                  _formatMsgTime(msg.timestamp),
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isTeacher ? Colors.white70 : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isTeacher) ...[
                                  const SizedBox(width: 4),
                                  _buildTickIcon(msg),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                }

                if (showDateSeparator && currDate != null) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateSeparator(currDate),
                      bubble,
                    ],
                  );
                }
                return bubble;
              },
            ),
          ),
          if (_showScrollToBottom)
            Positioned(
              right: 16,
              bottom: 12,
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: Colors.white,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _scrollToBottom(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                  
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      focusNode: _focusNode,
                      onTap: () {
                        _scrollToBottom(delayMs: 150);
                        _scrollToBottom(delayMs: 350);
                      },
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      enableSuggestions: true,
                      autocorrect: true,
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      minLines: 1,
                      maxLength: 1000,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        if (currentLength > 800) {
                          return Text(
                            '$currentLength / $maxLength',
                            style: TextStyle(
                              fontSize: 10,
                              color: currentLength >= 1000 ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return null;
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Type a message (max 1000 chars)...",
                        fillColor: const Color(0xFFF5F7FA),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(appState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final canSend = _msgController.text.trim().isNotEmpty;
                      return GestureDetector(
                        onTap: canSend ? () => _sendMessage(appState) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: canSend ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      );
                    },
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

class IconDataEx {
  static const IconData volumeUp = Icons.volume_up;
}
