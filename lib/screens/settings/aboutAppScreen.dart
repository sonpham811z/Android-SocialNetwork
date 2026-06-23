import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/languageProvider.dart';
import 'staticContentScreen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().translate;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('about_app'),
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(children: [
          // ===== APP HEADER =====
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_fbBlue, Color(0xFF42A5F5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _fbBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.people_alt_rounded, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(t('social_network'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.slate900)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _fbBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('${t('version')} 1.0.0', style: const TextStyle(color: _fbBlue, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Text(t('connect_share_inspire'),
              style: TextStyle(color: isDark ? AppTheme.slate500 : AppTheme.slate400, fontSize: 15, fontStyle: FontStyle.italic)),
          const SizedBox(height: 28),

          // ===== APP INFO =====
          _buildInfoCard(isDark, [
            _infoTile(t('version'), '1.0.0', Icons.info_outline, isDark),
            _divider(isDark),
            _infoTile(t('build_number'), '2026.05.26', Icons.build_outlined, isDark),
            _divider(isDark),
            _infoTile(t('developer'), 'Son Pham', Icons.code_rounded, isDark),
            _divider(isDark),
            _infoTile(t('website'), 'socialnetwork.app', Icons.language_rounded, isDark),
          ]),
          const SizedBox(height: 16),

          // ===== LEGAL =====
          _buildInfoCard(isDark, [
            _navTile(t('privacy_policy'), Icons.privacy_tip_outlined, isDark, context, 'privacy'),
            _divider(isDark),
            _navTile(t('terms_of_service'), Icons.description_outlined, isDark, context, 'terms'),
          ]),
          const SizedBox(height: 16),

          // ===== LICENSES =====
          _buildInfoCard(isDark, [
            _navTile(t('licenses'), Icons.article_outlined, isDark, context, 'licenses'),
            _divider(isDark),
            _navTile(t('acknowledgements'), Icons.favorite_border_rounded, isDark, context, 'acknowledgements'),
          ]),
          const SizedBox(height: 28),

          // ===== RATE BUTTON =====
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('thank_you_support')), behavior: SnackBarBehavior.floating)),
              icon: const Icon(Icons.star_rounded, size: 22),
              label: Text(t('rate_this_app'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _fbBlue, foregroundColor: Colors.white, elevation: 4,
                shadowColor: _fbBlue.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ===== COPYRIGHT =====
          Text(t('copyright'),
              style: TextStyle(color: isDark ? AppTheme.slate600 : AppTheme.slate400, fontSize: 12)),
          const SizedBox(height: 8),
          Text(t('made_in_vietnam'),
              style: TextStyle(color: isDark ? AppTheme.slate600 : AppTheme.slate400, fontSize: 12)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(String title, String value, IconData icon, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36, alignment: Alignment.center,
        decoration: BoxDecoration(color: _fbBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: _fbBlue),
      ),
      title: Text(title, style: TextStyle(color: isDark ? AppTheme.slate400 : AppTheme.slate500, fontSize: 13)),
      trailing: Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _navTile(String title, IconData icon, bool isDark, BuildContext context, String contentKey) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36, alignment: Alignment.center,
        decoration: BoxDecoration(color: isDark ? AppTheme.slate700 : AppTheme.slate100, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: isDark ? AppTheme.slate400 : AppTheme.slate500),
      ),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.slate500),
      onTap: () {
        final isVi = context.read<LanguageProvider>().languageCode == 'vi';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaticContentScreen(
              title: title,
              sections: _legalSections(contentKey, isVi),
            ),
          ),
        );
      },
    );
  }

  /// Nội dung tĩnh song ngữ cho các trang pháp lý.
  List<StaticSection> _legalSections(String key, bool vi) {
    switch (key) {
      case 'privacy':
        return vi
            ? const [
                StaticSection(
                    heading: 'Thu thập thông tin',
                    body: 'Chúng tôi thu thập thông tin bạn cung cấp khi đăng ký tài khoản (tên, email, ảnh đại diện) và nội dung bạn đăng tải (bài viết, bình luận, tin nhắn) nhằm cung cấp và cải thiện dịch vụ.'),
                StaticSection(
                    heading: 'Sử dụng thông tin',
                    body: 'Thông tin được dùng để hiển thị hồ sơ, kết nối bạn bè, gửi thông báo và đảm bảo an toàn tài khoản. Chúng tôi không bán dữ liệu cá nhân của bạn cho bên thứ ba.'),
                StaticSection(
                    heading: 'Quyền của bạn',
                    body: 'Bạn có thể chỉnh sửa hồ sơ, điều chỉnh quyền riêng tư trong phần Cài đặt, hoặc xóa tài khoản bất cứ lúc nào. Khi xóa, hồ sơ của bạn sẽ được ẩn khỏi hệ thống.'),
                StaticSection(
                    heading: 'Liên hệ',
                    body: 'Mọi thắc mắc về quyền riêng tư, vui lòng liên hệ nhóm phát triển qua mục Hỗ trợ.'),
              ]
            : const [
                StaticSection(
                    heading: 'Information We Collect',
                    body: 'We collect the information you provide when creating an account (name, email, avatar) and the content you post (posts, comments, messages) to provide and improve our services.'),
                StaticSection(
                    heading: 'How We Use Information',
                    body: 'Information is used to display your profile, connect you with friends, send notifications and keep your account secure. We do not sell your personal data to third parties.'),
                StaticSection(
                    heading: 'Your Rights',
                    body: 'You can edit your profile, adjust privacy in Settings, or delete your account at any time. When deleted, your profile is hidden from the system.'),
                StaticSection(
                    heading: 'Contact',
                    body: 'For any privacy questions, please reach out to the development team via the Support section.'),
              ];
      case 'terms':
        return vi
            ? const [
                StaticSection(
                    heading: 'Chấp nhận điều khoản',
                    body: 'Bằng việc sử dụng ứng dụng, bạn đồng ý tuân thủ các điều khoản này. Nếu không đồng ý, vui lòng ngừng sử dụng dịch vụ.'),
                StaticSection(
                    heading: 'Hành vi người dùng',
                    body: 'Bạn cam kết không đăng tải nội dung vi phạm pháp luật, quấy rối, spam hoặc xâm phạm quyền của người khác. Chúng tôi có quyền gỡ nội dung và khóa tài khoản vi phạm.'),
                StaticSection(
                    heading: 'Nội dung của bạn',
                    body: 'Bạn giữ quyền sở hữu nội dung mình đăng, nhưng cấp cho chúng tôi quyền hiển thị nội dung đó trong phạm vi vận hành dịch vụ.'),
                StaticSection(
                    heading: 'Thay đổi điều khoản',
                    body: 'Điều khoản có thể được cập nhật theo thời gian. Việc tiếp tục sử dụng đồng nghĩa bạn chấp nhận các thay đổi.'),
              ]
            : const [
                StaticSection(
                    heading: 'Acceptance of Terms',
                    body: 'By using the app, you agree to comply with these terms. If you do not agree, please stop using the service.'),
                StaticSection(
                    heading: 'User Conduct',
                    body: 'You agree not to post unlawful, harassing, spam, or rights-infringing content. We may remove content and suspend violating accounts.'),
                StaticSection(
                    heading: 'Your Content',
                    body: 'You retain ownership of content you post, but grant us the right to display it as needed to operate the service.'),
                StaticSection(
                    heading: 'Changes to Terms',
                    body: 'These terms may be updated over time. Continued use means you accept the changes.'),
              ];
      case 'licenses':
        return const [
          StaticSection(
              body: 'This app is built with Flutter and uses the following key open-source packages, each under its respective license (MIT/BSD/Apache-2.0):\n\n• provider\n• dio\n• video_player\n• signalr_netcore\n• agora_rtc_engine\n• firebase_core / firebase_messaging\n• image_picker / file_picker\n• shared_preferences / flutter_secure_storage\n\nFull license texts are available in each package repository on pub.dev.'),
        ];
      case 'acknowledgements':
        return vi
            ? const [
                StaticSection(
                    body: 'Ứng dụng được phát triển bởi nhóm sinh viên UIT trong khuôn khổ môn Phát triển ứng dụng trên thiết bị di động.\n\nXin cảm ơn cộng đồng mã nguồn mở Flutter và .NET đã cung cấp các công cụ tuyệt vời giúp dự án này thành hiện thực.'),
              ]
            : const [
                StaticSection(
                    body: 'This app was developed by a UIT student team as part of the Mobile Application Development course.\n\nThanks to the Flutter and .NET open-source communities for the excellent tools that made this project possible.'),
              ];
      default:
        return const [StaticSection(body: '')];
    }
  }

  Widget _divider(bool isDark) {
    return Divider(height: 1, indent: 64, color: isDark ? AppTheme.slate700.withOpacity(0.5) : AppTheme.slate200);
  }
}
