import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

class SchoolNoticeScreen extends StatefulWidget {
  const SchoolNoticeScreen({super.key});

  @override
  State<SchoolNoticeScreen> createState() => _SchoolNoticeScreenState();
}

class _SchoolNoticeScreenState extends State<SchoolNoticeScreen> {
  String _searchTerm = '';
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isFetching = true);
    await Provider.of<AppState>(context, listen: false).refreshBroadcasts();
    if (mounted) setState(() => _isFetching = false);
  }

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
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    final filteredNotices = appState.notices.where((notice) {
      final query = _searchTerm.toLowerCase();
      return notice.title.toLowerCase().contains(query) ||
          notice.body.toLowerCase().contains(query);
    }).toList();

    // Sort by date descending
    filteredNotices.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: Column(
        children: [
          // Header & Search
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      appState.language == 'mr'
                          ? 'शाळेच्या सूचना'
                          : appState.language == 'hi'
                              ? 'स्कूल नोटिस'
                              : 'School Notice',
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
                      _searchTerm = val;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white60),
                    hintText: '${appState.translate('search')}...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Notices list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => appState.refreshBroadcasts(),
              color: AppColors.primary,
              child: filteredNotices.isNotEmpty
                  ? ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredNotices.length,
                      itemBuilder: (context, index) {
                        final notice = filteredNotices[index];
                        final isUnread = !appState.isNoticeRead(notice.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnread ? AppColors.primary.withValues(alpha: 0.5) : const Color(0xFFE5E7EB),
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
                                appState.markNoticeAsRead(notice.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SchoolNoticeDetailScreen(notice: notice),
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
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.campaign, color: AppColors.primary),
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
                                                            decoration: const BoxDecoration(
                                                              color: AppColors.primary,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                        Expanded(
                                                          child: Text(
                                                            notice.title,
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
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatDate(notice.date, appState.language),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                notice.source,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      notice.body,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: Color(0xFFF9FAFB)),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        appState.language == 'mr'
                                            ? 'अधिक वाचा →'
                                            : appState.language == 'hi'
                                                ? 'और पढ़ें →'
                                                : 'Read More →',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: _isFetching
                              ? const CircularProgressIndicator(color: AppColors.primary)
                              : Text(
                                  appState.language == 'mr'
                                      ? 'कोणतीही सूचना सापडली नाही'
                                      : appState.language == 'hi'
                                          ? 'कोई नोटिस नहीं मिला'
                                          : 'No notices found',
                                  style: const TextStyle(color: Colors.grey),
                                ),
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

class SchoolNoticeDetailScreen extends StatelessWidget {
  final Notice notice;

  const SchoolNoticeDetailScreen({
    super.key,
    required this.notice,
  });

  String _formatDate(String dateStr, String language) {
    try {
      final date = DateTime.parse(dateStr);
      final locale = language == 'mr' ? 'mr_IN' : language == 'hi' ? 'hi_IN' : 'en_US';
      return DateFormat('d MMM yyyy', locale).format(date);
    } catch (e) {
      return dateStr;
    }
  }

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
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF006D63)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign, color: Colors.white70, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                notice.source.toUpperCase(),
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
                            notice.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(notice.date, appState.language),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                notice.time,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Message Title
                    Text(
                      appState.language == 'mr' ? 'संदेश' : appState.language == 'hi' ? 'संदेश' : 'Message',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.body,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                    
                    // CTA Button if exists
                    if (notice.cta != null) ...[
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Action '${notice.cta!.label}' is parent-facing. Optimizations available in the Parent App."),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppColors.secondary.withValues(alpha: 0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                notice.cta!.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            ],
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
