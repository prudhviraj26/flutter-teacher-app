import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';

class ComingSoonScreen extends StatelessWidget {
  final String featureKey;

  const ComingSoonScreen({
    super.key,
    required this.featureKey,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String currentLang = appState.language;

    // Map feature key to details
    final bool isOrange = _getIsOrange(featureKey);
    final Color themeColor = isOrange ? AppColors.secondary : AppColors.primary;
    final IconData icon = _getFeatureIcon(featureKey);
    final String title = _getTranslatedTitle(appState, featureKey);
    final String description = _getFeatureDescription(featureKey, currentLang);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                color: themeColor,
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
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Main Feature Icon in glowing container
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 48,
                                color: themeColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Pulsing Rocket Icon Container
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFA41B), Color(0xFFFF9500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFA41B).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.rocket_launch_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Coming Soon Text
                          Text(
                            appState.translate('comingSoon'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Working hard card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x05000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                )
                              ],
                              border: Border.all(
                                color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              currentLang == 'mr'
                                  ? 'आम्ही हे वैशिष्ठ्य तुमच्यासाठी आणण्यासाठी कठोर परिश्रम करत आहोत. अपडेट्ससाठी संपर्कात रहा!'
                                  : currentLang == 'hi'
                                      ? 'हम इस सुविधा को आपके पास लाने के लिए कड़ी मेहनत कर रहे हैं। अपडेट के लिए बने रहें!'
                                      : "We're working hard to bring you this feature. Stay tuned for updates!",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Fixed Bottom Go Back Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480),
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: themeColor.withValues(alpha: 0.4),
                ),
                child: Text(
                  appState.translate('goBackToDashboard'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _getIsOrange(String key) {
    switch (key) {
      case 'examResults':
      case 'feedback':
      case 'privacySecurity':
      case 'help':
      case 'learningDevelopment':
        return true;
      default:
        return false;
    }
  }

  IconData _getFeatureIcon(String key) {
    switch (key) {
      case 'learningDevelopment':
        return Icons.school_outlined;
      case 'examResults':
        return Icons.description_outlined;
      case 'healthRecords':
        return Icons.favorite_border_outlined;
      case 'examDetails':
        return Icons.calendar_month_outlined;
      case 'library':
        return Icons.local_library_outlined;
      case 'teacherProfile':
        return Icons.person_outline;
      case 'changePassword':
        return Icons.lock_outline;
      case 'feedback':
        return Icons.chat_bubble_outline;
      case 'aboutUs':
        return Icons.info_outline;
      case 'help':
        return Icons.help_outline;
      case 'privacySecurity':
        return Icons.shield_outlined;
      default:
        return Icons.rocket_launch_outlined;
    }
  }

  String _getTranslatedTitle(AppState state, String key) {
    // Check if key is available in translations
    final trans = state.translate(key);
    if (trans != key) return trans;

    // Fallbacks
    switch (key) {
      case 'teacherProfile':
        return state.translate('teacherProfile');
      case 'changePassword':
        return state.translate('changePassword');
      case 'feedback':
        return state.translate('feedback');
      case 'aboutUs':
        return state.translate('aboutUs');
      case 'help':
        return state.translate('help');
      case 'privacySecurity':
        return state.translate('privacySecurity');
      default:
        return key;
    }
  }

  String _getFeatureDescription(String key, String lang) {
    if (lang == 'mr') {
      switch (key) {
        case 'learningDevelopment':
          return 'व्यावसायिक विकास अभ्यासक्रम, प्रशिक्षण साहित्य आणि शैक्षणिक संसाधने लवकरच येथे उपलब्ध होतील.';
        case 'examResults':
          return 'परीक्षा निकाल, कामगिरी विश्लेषण आणि श्रेणी व्यवस्थापन साधने लवकरच उपलब्ध होतील.';
        case 'healthRecords':
          return 'विद्यार्थ्यांच्या वैद्यकीय नोंदी, उंची/वजन ट्रॅकर्स आणि लसीकरण रेकॉर्ड येथे दर्शविले जातील.';
        case 'examDetails':
          return 'वर्गवार परीक्षा वेळापत्रक, अभ्यासक्रम तपशील आणि मूल्यमापन वेळापत्रक येथे शोधा.';
        case 'library':
          return 'शाळेच्या ग्रंथालयातील पुस्तके ब्राउझ करा, विद्यार्थ्यांनी पुस्तक घेतल्याचा इतिहास ट्रॅक करा आणि पुस्तकाची उपलब्धता तपासा.';
        case 'teacherProfile':
          return 'तुमची शैक्षणिक क्रेडेन्शियल्स संपादित करा, प्रमाणपत्रे अपलोड करा आणि येथे प्रोफाइल अपडेटची विनंती करा.';
        case 'changePassword':
          return 'तुमचा खाते संकेतशब्द अपडेट करा, सक्रिय सत्रे व्यवस्थापित करा आणि सुरक्षा प्रश्न कॉन्फिगर करा.';
        case 'feedback':
          return 'थेट तांत्रिक टीमकडे नवीन वैशिष्ट्यांच्या विनंत्या, ॲप अभिप्राय, बग अहवाल सबमिट करा.';
        case 'aboutUs':
          return 'वेहो स्कूल प्लॅटफॉर्मचा इतिहास, डेव्हलपर्स, संपर्क माहिती आणि व्हिजनबद्दल जाणून घ्या.';
        case 'help':
          return 'ट्युटोरियल्स, वापरकर्ता मार्गदर्शक शोधा, FAQ शोधा किंवा प्रशासक सपोर्टची विनंती करा.';
        case 'privacySecurity':
          return 'डेटा संमती सेटिंग्जचे पुनरावलोकन करा, गोपनीयता धोरण दस्तऐवज वाचा आणि परवानग्या नियंत्रित करा.';
        default:
          return 'हे वैशिष्ट्य लवकरच उपलब्ध होईल.';
      }
    } else if (lang == 'hi') {
      switch (key) {
        case 'learningDevelopment':
          return 'व्यावसायिक विकास पाठ्यक्रम, प्रशिक्षण सामग्री और शिक्षण संसाधन जल्द ही यहाँ उपलब्ध होंगे।';
        case 'examResults':
          return 'परीक्षा परिणाम, प्रदर्शन विश्लेषण और ग्रेड प्रबंधन उपकरण जल्द ही उपलब्ध होंगे।';
        case 'healthRecords':
          return 'छात्रों के मेडिकल लॉग, ऊंचाई/वजन ट्रैकर और टीकाकरण रिकॉर्ड यहां दिखाए जाएंगे।';
        case 'examDetails':
          return 'कक्षा-वार परीक्षा कार्यक्रम, पाठ्यक्रम विवरण और मूल्यांकन समय-सारणी यहां पाएं।';
        case 'library':
          return 'स्कूल पुस्तकालय की पुस्तकें ब्राउज़ करें, छात्रों के उधार लेने के इतिहास को ट्रैक करें और पुस्तक उपलब्धता की जाँच करें।';
        case 'teacherProfile':
          return 'अपनी शैक्षणिक साख संपादित करें, प्रमाण पत्र अपलोड करें और यहां प्रोफ़ाइल अपडेट का अनुरोध करें।';
        case 'changePassword':
          return 'अपना खाता पासवर्ड अपडेट करें, सक्रिय सत्र प्रबंधित करें और सुरक्षा प्रश्न कॉन्फ़िगर करें।';
        case 'feedback':
          return 'तकनीकी टीम को सीधे फीचर अनुरोध, ऐप प्रतिक्रिया, बग रिपोर्ट सबमिट करें।';
        case 'aboutUs':
          return 'वेहो स्कूल प्लेटफॉर्म इतिहास, डेवलपर्स, संपर्क जानकारी और विजन के बारे में जानें।';
        case 'help':
          return 'ट्यूटोरियल, उपयोगकर्ता गाइड खोजें, अक्सर पूछे जाने वाले प्रश्नों को खोजें, या व्यवस्थापक सहायता का अनुरोध करें।';
        case 'privacySecurity':
          return 'डेटा सहमति सेटिंग्स की समीक्षा करें, गोपनीयता नीति दस्तावेज़ पढ़ें, और अनुमतियाँ नियंत्रित करें।';
        default:
          return 'यह सुविधा जल्द ही उपलब्ध होगी।';
      }
    } else {
      switch (key) {
        case 'learningDevelopment':
          return 'Professional development courses, training materials, and teaching resources will be available here soon.';
        case 'examResults':
          return 'Access exam results, performance analytics, and grade management tools coming soon.';
        case 'healthRecords':
          return 'Student medical logs, height/weight trackers, and vaccination records will be shown here.';
        case 'examDetails':
          return 'Find class-wise exam schedules, syllabus details, and assessment timetables here.';
        case 'library':
          return 'Browse school library books, track student borrowing history, and check book availability.';
        case 'teacherProfile':
          return 'Edit your educational credentials, upload certificates, and request profile updates here.';
        case 'changePassword':
          return 'Update your account password, manage active sessions, and configure security questions.';
        case 'feedback':
          return 'Submit feature requests, app feedback, bug reports directly to the technical team.';
        case 'aboutUs':
          return 'Learn about the Veyho school platform history, developers, contact info, and vision.';
        case 'help':
          return 'Find tutorials, user guides, search through FAQs, or request administrator support.';
        case 'privacySecurity':
          return 'Review data consent settings, read privacy policy documents, and control permissions.';
        default:
          return 'This feature will be available soon.';
      }
    }
  }
}
