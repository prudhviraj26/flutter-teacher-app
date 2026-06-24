import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

class StaffNoticeScreen extends StatelessWidget {
  const StaffNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final notices = appState.staffNotices;

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
                  appState.language == 'mr'
                      ? 'कर्मचारी सूचना'
                      : appState.language == 'hi'
                          ? 'स्टाफ नोटिस'
                          : 'Staff Notice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                // Info Banner
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7), // bg-amber-50
                    border: Border.all(color: const Color(0xFFFDE68A)), // border-amber-200
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
                              appState.language == 'mr'
                                  ? 'प्रशासकीय सूचना फलक'
                                  : appState.language == 'hi'
                                      ? 'प्रशासनिक सूचना बोर्ड'
                                      : 'Staff-Only Circulars',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF78350F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appState.language == 'mr'
                                  ? 'तुम्ही शाळा प्रशासनाद्वारे केवळ शिक्षक आणि कर्मचाऱ्यांसाठी पाठवलेल्या अधिकृत सूचना पाहत आहात.'
                                  : appState.language == 'hi'
                                      ? 'आप स्कूल प्रशासन द्वारा केवल शिक्षकों और कर्मचारियों के लिए भेजी गई आधिकारिक सूचनाएं देख रहे हैं.'
                                      : 'You are viewing official circulars issued by school administration specifically for teachers and staff.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB45309),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // List of notices
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    final isTeal = index % 2 == 0;
                    final iconBg = isTeal ? AppColors.primary.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1);
                    final iconColor = isTeal ? AppColors.primary : AppColors.secondary;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
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
                                builder: (context) => StaffNoticeDetailScreen(
                                  notice: notice,
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
                                            notice.title,
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
                                              Text(
                                                notice.author,
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('•', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.calendar_month, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                notice.date,
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  notice.message,
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
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: notice.category == 'Urgent' ? Colors.red.shade50 : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: notice.category == 'Urgent'
                                            ? Border.all(color: Colors.red.shade100)
                                            : null,
                                      ),
                                      child: Text(
                                        notice.category,
                                        style: TextStyle(
                                          color: notice.category == 'Urgent' ? Colors.red.shade600 : Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
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
                                  ],
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
                                notice.category.toUpperCase(),
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
                          const SizedBox(height: 6),
                          Text(
                            notice.author,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
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
                    
                    // Actions
                    const Divider(color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 12),
                    
                    _buildActionItem(
                      icon: Icons.download_outlined,
                      color: themeColor,
                      label: appState.language == 'mr'
                          ? 'अधिकृत परिपत्रक डाउनलोड करा'
                          : appState.language == 'hi'
                              ? 'आधिकारिक परिपत्रक डाउनलोड करें'
                              : 'Download PDF Circular',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading official PDF circular...')),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      icon: Icons.share_outlined,
                      color: themeColor,
                      label: appState.language == 'mr'
                          ? 'इतरांसह शेअर करा'
                          : appState.language == 'hi'
                              ? 'दूसरों के साथ साझा करें'
                              : 'Share Notice Circular',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sharing link copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4B5563),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
