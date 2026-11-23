import '../widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/attachment_local_store.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

class StaffNoticeScreen extends StatefulWidget {
  const StaffNoticeScreen({super.key});

  @override
  State<StaffNoticeScreen> createState() => _StaffNoticeScreenState();
}

class _StaffNoticeScreenState extends State<StaffNoticeScreen> {
  bool _isFetching = false;
  bool _isSearchOpen = false;
  bool _isBannerDismissed = false;
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  String _formatDate(String dateStr, String language) {
    try {
      final date = DateTime.parse(dateStr);
      final locale = language == 'mr' ? 'mr_IN' : language == 'hi' ? 'hi_IN' : 'en_GB';
      return DateFormat('d MMM yyyy', locale).format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isFetching = true);
    await Provider.of<AppState>(context, listen: false).refreshBroadcasts();
    if (mounted) setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final notices = appState.staffNotices;

    final filteredNotices = notices.where((notice) {
      final q = _searchTerm.toLowerCase().trim();
      if (q.isEmpty) return true;
      return notice.title.toLowerCase().contains(q) ||
          notice.message.toLowerCase().contains(q) ||
          notice.author.toLowerCase().contains(q) ||
          notice.category.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.secondary,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
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
                                  ? 'कर्मचारी सूचना शोधा...'
                                  : appState.language == 'hi'
                                      ? 'स्टाफ नोटिस खोजें...'
                                      : 'Search staff notices...',
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
                              child: Text(
                                appState.language == 'mr'
                                    ? 'कर्मचारी सूचना'
                                    : appState.language == 'hi'
                                        ? 'स्टाफ नोटिस'
                                        : 'Staff Notice',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (appState.unreadStaffNoticesCount > 0) ...[
                            GestureDetector(
                              onTap: () async {
                                await appState.markAllStaffNoticesAsRead();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appState.language == 'mr'
                                            ? 'सर्व सूचना वाचल्या म्हणून चिन्हांकित केल्या'
                                            : appState.language == 'hi'
                                                ? 'सभी नोटिस पढ़े हुए चिह्नित किए गए'
                                                : 'All notices marked as read',
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
                            onTap: _isFetching ? null : _fetchData,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: _isFetching
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
                // Info Banner
                if (!_isBannerDismissed) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7), // bg-amber-50
                      border: Border.all(color: const Color(0xFFFDE68A)), // border-amber-200
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appState.language == 'mr'
                                ? 'केवळ शिक्षक आणि कर्मचाऱ्यांसाठी अधिकृत प्रशासकीय परिपत्रके'
                                : appState.language == 'hi'
                                    ? 'केवल शिक्षकों और कर्मचारियों के लिए आधिकारिक परिपत्र'
                                    : 'Official circulars issued for teachers & staff',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isBannerDismissed = true),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.close, size: 14, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                
                // List of notices
                if (notices.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: _isFetching
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: AppColors.secondary),
                            ),
                          )
                        : Column(
                            children: [
                              Icon(Icons.mark_email_read_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                appState.language == 'mr'
                                    ? 'सध्या कोणतीही कर्मचारी सूचना नाही'
                                    : appState.language == 'hi'
                                        ? 'वर्तमान में कोई स्टाफ नोटिस नहीं है'
                                        : 'No staff circulars posted yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                  )
                else if (filteredNotices.isEmpty)
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
                          'No staff notices match "$_searchTerm". Try searching with different keywords.',
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
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: filteredNotices.length,
                    itemBuilder: (context, index) {
                      final notice = filteredNotices[index];
                      final isUnread = !appState.isNoticeRead(notice.id);
                      final isTeal = index % 2 == 0;
                      final iconColor = isTeal ? AppColors.primary : AppColors.secondary;
                      final hasAttachments = notice.attachments.isNotEmpty;
                      final attachmentCount = notice.attachments.length;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isUnread ? iconColor.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
                              width: isUnread ? 1.2 : 1.0,
                            ),
                            boxShadow: isUnread
                                ? [
                                    BoxShadow(
                                      color: iconColor.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : const [
                                    BoxShadow(
                                      color: Color(0x04000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: InkWell(
                            onTap: () {
                              appState.markStaffNoticeAsRead(notice.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StaffNoticeDetailScreen(
                                    notice: notice,
                                    themeColor: iconColor,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: isUnread ? iconColor.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.campaign,
                                          color: isUnread ? iconColor : const Color(0xFF64748B),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (isUnread) ...[
                                                  Container(
                                                    width: 6.5,
                                                    height: 6.5,
                                                    margin: const EdgeInsets.only(right: 6),
                                                    decoration: BoxDecoration(
                                                      color: iconColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    notice.title,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                      color: isUnread ? const Color(0xFF1F2937) : const Color(0xFF334155),
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
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                if (notice.category == 'Urgent') ...[
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 5),
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEE2E2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'URGENT',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFFDC2626),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (notice.author.isNotEmpty) ...[
                                                  Flexible(
                                                    child: Text(
                                                      notice.author,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF64748B),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    '•',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                const Icon(
                                                  Icons.calendar_month,
                                                  size: 12,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDate(notice.date, appState.language),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (notice.message.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 44),
                                      child: Text(
                                        notice.message.trim(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
        ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentRoute: '/staff-notice'),
    );
  }
}

class StaffNoticeDetailScreen extends StatelessWidget {
  final StaffNotice notice;
  final Color themeColor;

  const StaffNoticeDetailScreen({
    super.key,
    required this.notice,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
                  appState.language == 'mr'
                      ? 'सूचनेचा तपशील'
                      : appState.language == 'hi'
                          ? 'सूचना विवरण'
                          : 'Notice Details',
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
          
          // Content Card
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
                          if (notice.category == 'Urgent') ...[
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'URGENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            notice.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notice.author,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${notice.date} at ${notice.time}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Message
                    Text(
                      appState.language == 'mr' ? 'संदेश' : appState.language == 'hi' ? 'संदेश' : 'Message',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Attachments Section
                    if (notice.attachments.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.attach_file, color: themeColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'ATTACHMENTS (${notice.attachments.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...notice.attachments.map((att) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                att.name.toLowerCase().endsWith('.pdf')
                                    ? Icons.picture_as_pdf
                                    : Icons.insert_drive_file_outlined,
                                color: themeColor,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              att.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151),
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
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.remove_red_eye_outlined, size: 14, color: themeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              final key = att.blobPath?.isNotEmpty == true ? att.blobPath! : att.url;
                              await AttachmentLocalStore.openAttachment(
                                context: context,
                                key: key,
                                url: att.url,
                                dateStr: notice.fullDate ?? notice.date,
                                originalFileName: att.name,
                              );
                            },
                          ),
                        );
                      }),
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
