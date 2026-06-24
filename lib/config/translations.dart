/// All UI string translations for the app.
/// Keys are organized by screen / feature area.
const Map<String, Map<String, String>> translations = {
  // ═══════════════════════════════════════════════
  // SETTINGS SCREEN
  // ═══════════════════════════════════════════════
  'settings': {'en': 'Settings', 'vi': 'Cài đặt'},
  'account': {'en': 'Account', 'vi': 'Tài khoản'},
  'personal_information': {'en': 'Personal Information', 'vi': 'Thông tin cá nhân'},
  'change_password': {'en': 'Change Password', 'vi': 'Đổi mật khẩu'},
  'preferences': {'en': 'Preferences', 'vi': 'Tùy chọn'},
  'notifications': {'en': 'Notifications', 'vi': 'Thông báo'},
  'display_theme': {'en': 'Display & Theme', 'vi': 'Hiển thị & Giao diện'},
  'language': {'en': 'Language', 'vi': 'Ngôn ngữ'},
  'support': {'en': 'Support', 'vi': 'Hỗ trợ'},
  'help_center': {'en': 'Help Center', 'vi': 'Trung tâm trợ giúp'},
  'about_app': {'en': 'About App', 'vi': 'Về ứng dụng'},
  'log_out': {'en': 'Log Out', 'vi': 'Đăng xuất'},
  'log_out_confirm': {'en': 'Are you sure you want to log out of your account?', 'vi': 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'},
  'cancel': {'en': 'Cancel', 'vi': 'Hủy'},
  'feature_coming_soon': {'en': 'Feature coming soon!', 'vi': 'Tính năng sắp ra mắt!'},
  'privacy_security': {'en': 'Privacy & Security', 'vi': 'Quyền riêng tư & Bảo mật'},
  'saved_posts': {'en': 'Saved Posts', 'vi': 'Bài viết đã lưu'},

  // ═══════════════════════════════════════════════
  // PRIVACY SETTINGS SCREEN
  // ═══════════════════════════════════════════════
  'privacy_settings': {'en': 'Privacy Settings', 'vi': 'Cài đặt quyền riêng tư'},
  'profile_visibility': {'en': 'Profile Visibility', 'vi': 'Hiển thị trang cá nhân'},
  'profile_visibility_desc': {'en': 'Who can view your profile', 'vi': 'Ai có thể xem trang cá nhân của bạn'},
  'who_can_see_email': {'en': 'Who Can See Email', 'vi': 'Ai có thể xem email'},
  'who_can_see_email_desc': {'en': 'Control who sees your email address', 'vi': 'Kiểm soát ai thấy địa chỉ email của bạn'},
  'who_can_see_friends': {'en': 'Who Can See Friends', 'vi': 'Ai có thể xem bạn bè'},
  'who_can_see_friends_desc': {'en': 'Control who sees your friends list', 'vi': 'Kiểm soát ai thấy danh sách bạn bè'},
  'who_can_send_request': {'en': 'Who Can Send Friend Request', 'vi': 'Ai có thể gửi lời mời kết bạn'},
  'who_can_send_request_desc': {'en': 'Control who can add you as a friend', 'vi': 'Kiểm soát ai có thể kết bạn với bạn'},
  'visibility_public': {'en': 'Public', 'vi': 'Công khai'},
  'visibility_friends': {'en': 'Friends', 'vi': 'Bạn bè'},
  'visibility_only_me': {'en': 'Only Me', 'vi': 'Chỉ mình tôi'},
  'visibility_everyone': {'en': 'Everyone', 'vi': 'Mọi người'},
  'privacy_saved': {'en': 'Privacy settings saved', 'vi': 'Đã lưu cài đặt quyền riêng tư'},
  'save_failed': {'en': 'Failed to save', 'vi': 'Lưu thất bại'},

  // ═══════════════════════════════════════════════
  // DELETE ACCOUNT
  // ═══════════════════════════════════════════════
  'danger_zone': {'en': 'Danger Zone', 'vi': 'Vùng nguy hiểm'},
  'delete_account': {'en': 'Delete Account', 'vi': 'Xóa tài khoản'},
  'delete_account_title': {'en': 'Delete your account?', 'vi': 'Xóa tài khoản của bạn?'},
  'delete_account_confirm': {
    'en': 'Your account will be deactivated and your profile hidden. This action cannot be easily undone. Continue?',
    'vi': 'Tài khoản của bạn sẽ bị vô hiệu hóa và hồ sơ bị ẩn. Thao tác này không thể dễ dàng hoàn tác. Tiếp tục?'
  },
  'delete_account_success': {'en': 'Account deleted', 'vi': 'Đã xóa tài khoản'},
  'delete_account_failed': {'en': 'Failed to delete account', 'vi': 'Không thể xóa tài khoản'},
  'delete': {'en': 'Delete', 'vi': 'Xóa'},
  'remove_cover_photo': {'en': 'Remove cover photo', 'vi': 'Xóa ảnh bìa'},
  'cover_photo_removed': {'en': 'Cover photo removed', 'vi': 'Đã xóa ảnh bìa'},

  // ═══════════════════════════════════════════════
  // LANGUAGE SCREEN
  // ═══════════════════════════════════════════════
  'search_language': {'en': 'Search language...', 'vi': 'Tìm kiếm ngôn ngữ...'},
  'no_languages_found': {'en': 'No languages found', 'vi': 'Không tìm thấy ngôn ngữ'},

  // ═══════════════════════════════════════════════
  // DISPLAY & THEME SCREEN
  // ═══════════════════════════════════════════════
  'theme': {'en': 'Theme', 'vi': 'Giao diện'},
  'light': {'en': 'Light', 'vi': 'Sáng'},
  'dark': {'en': 'Dark', 'vi': 'Tối'},
  'system': {'en': 'System', 'vi': 'Hệ thống'},
  'text_size': {'en': 'Text Size', 'vi': 'Cỡ chữ'},
  'font_size': {'en': 'Font Size', 'vi': 'Kích cỡ phông'},
  'preview_text': {'en': 'Preview Text', 'vi': 'Văn bản mẫu'},
  'accessibility': {'en': 'Accessibility', 'vi': 'Trợ năng'},
  'reduce_motion': {'en': 'Reduce Motion', 'vi': 'Giảm chuyển động'},
  'reduce_motion_desc': {'en': 'Minimize animations throughout the app', 'vi': 'Giảm thiểu hiệu ứng chuyển động trong ứng dụng'},
  'high_contrast': {'en': 'High Contrast', 'vi': 'Tương phản cao'},
  'high_contrast_desc': {'en': 'Increase contrast for better visibility', 'vi': 'Tăng độ tương phản để dễ nhìn hơn'},

  // ═══════════════════════════════════════════════
  // NOTIFICATIONS SCREEN
  // ═══════════════════════════════════════════════
  'general': {'en': 'General', 'vi': 'Chung'},
  'push_notifications': {'en': 'Push Notifications', 'vi': 'Thông báo đẩy'},
  'push_notifications_desc': {'en': 'Receive push notifications on your device', 'vi': 'Nhận thông báo đẩy trên thiết bị của bạn'},
  'email_notifications': {'en': 'Email Notifications', 'vi': 'Thông báo qua Email'},
  'email_notifications_desc': {'en': 'Receive notifications via email', 'vi': 'Nhận thông báo qua email'},
  'sms_notifications': {'en': 'SMS Notifications', 'vi': 'Thông báo qua SMS'},
  'sms_notifications_desc': {'en': 'Receive notifications via text message', 'vi': 'Nhận thông báo qua tin nhắn văn bản'},
  'activity': {'en': 'Activity', 'vi': 'Hoạt động'},
  'likes': {'en': 'Likes', 'vi': 'Lượt thích'},
  'likes_desc': {'en': 'Someone liked your post', 'vi': 'Ai đó đã thích bài viết của bạn'},
  'comments': {'en': 'Comments', 'vi': 'Bình luận'},
  'comments_desc': {'en': 'Someone commented on your post', 'vi': 'Ai đó đã bình luận bài viết của bạn'},
  'mentions': {'en': 'Mentions', 'vi': 'Đề cập'},
  'mentions_desc': {'en': 'Someone mentioned you', 'vi': 'Ai đó đã đề cập đến bạn'},
  'new_followers': {'en': 'New Followers', 'vi': 'Người theo dõi mới'},
  'new_followers_desc': {'en': 'Someone started following you', 'vi': 'Ai đó đã bắt đầu theo dõi bạn'},
  'messages': {'en': 'Messages', 'vi': 'Tin nhắn'},
  'message_requests': {'en': 'Message Requests', 'vi': 'Yêu cầu tin nhắn'},
  'message_requests_desc': {'en': 'Receive notifications for message requests', 'vi': 'Nhận thông báo cho các yêu cầu tin nhắn'},
  'direct_messages': {'en': 'Direct Messages', 'vi': 'Tin nhắn trực tiếp'},
  'direct_messages_desc': {'en': 'Receive notifications for new messages', 'vi': 'Nhận thông báo cho tin nhắn mới'},

  // ═══════════════════════════════════════════════
  // PERSONAL INFORMATION SCREEN
  // ═══════════════════════════════════════════════
  'full_name': {'en': 'Full Name', 'vi': 'Họ và tên'},
  'username': {'en': 'Username', 'vi': 'Tên người dùng'},
  'email': {'en': 'Email', 'vi': 'Email'},
  'phone': {'en': 'Phone', 'vi': 'Điện thoại'},
  'date_of_birth': {'en': 'Date of Birth', 'vi': 'Ngày sinh'},
  'bio': {'en': 'Bio', 'vi': 'Tiểu sử'},
  'bio_hint': {'en': 'Tell something about yourself...', 'vi': 'Hãy kể điều gì đó về bạn...'},
  'save_changes': {'en': 'Save Changes', 'vi': 'Lưu thay đổi'},
  'no_changes_to_save': {'en': 'No changes to save', 'vi': 'Không có thay đổi để lưu'},
  'profile_updated': {'en': 'Profile updated successfully!', 'vi': 'Cập nhật hồ sơ thành công!'},
  'profile_update_failed': {'en': 'Failed to update profile', 'vi': 'Cập nhật hồ sơ thất bại'},
  'full_name_required': {'en': 'Full name is required', 'vi': 'Họ tên là bắt buộc'},
  'uploading': {'en': 'Uploading...', 'vi': 'Đang tải lên...'},
  'profile_picture_updated': {'en': 'Profile picture updated!', 'vi': 'Ảnh đại diện đã được cập nhật!'},
  'profile_picture_failed': {'en': 'Failed to upload picture', 'vi': 'Tải ảnh lên thất bại'},

  // ═══════════════════════════════════════════════
  // CHANGE PASSWORD SCREEN
  // ═══════════════════════════════════════════════
  'create_new_password': {'en': 'Create a new password', 'vi': 'Tạo mật khẩu mới'},
  'password_instruction': {'en': 'Your new password must be different from previous used passwords.', 'vi': 'Mật khẩu mới của bạn phải khác với các mật khẩu đã sử dụng trước đó.'},
  'current_password': {'en': 'Current Password', 'vi': 'Mật khẩu hiện tại'},
  'new_password': {'en': 'New Password', 'vi': 'Mật khẩu mới'},
  'confirm_new_password': {'en': 'Confirm New Password', 'vi': 'Xác nhận mật khẩu mới'},
  'update_password': {'en': 'Update Password', 'vi': 'Cập nhật mật khẩu'},
  'enter_current_password': {'en': 'Please enter your current password', 'vi': 'Vui lòng nhập mật khẩu hiện tại'},
  'enter_new_password': {'en': 'Please enter a new password', 'vi': 'Vui lòng nhập mật khẩu mới'},
  'password_min_length': {'en': 'Password must be at least 8 characters', 'vi': 'Mật khẩu phải có ít nhất 8 ký tự'},
  'password_must_differ': {'en': 'New password must be different from the old one', 'vi': 'Mật khẩu mới phải khác mật khẩu cũ'},
  'confirm_password_required': {'en': 'Please confirm your new password', 'vi': 'Vui lòng xác nhận mật khẩu mới'},
  'passwords_not_match': {'en': 'Passwords do not match', 'vi': 'Mật khẩu không khớp'},
  'password_changed_success': {'en': 'Password changed successfully!', 'vi': 'Đổi mật khẩu thành công!'},
  'password_changed_failed': {'en': 'Failed to change password!', 'vi': 'Đổi mật khẩu thất bại!'},

  // ═══════════════════════════════════════════════
  // HELP CENTER SCREEN
  // ═══════════════════════════════════════════════
  'search_help_center': {'en': 'Search Help Center', 'vi': 'Tìm kiếm Trung tâm trợ giúp'},
  'browse_topics': {'en': 'Browse Topics', 'vi': 'Duyệt chủ đề'},
  'getting_started': {'en': 'Getting Started', 'vi': 'Bắt đầu'},
  'privacy_safety': {'en': 'Privacy & Safety', 'vi': 'Quyền riêng tư & An toàn'},
  'account_settings': {'en': 'Account Settings', 'vi': 'Cài đặt tài khoản'},
  'payments': {'en': 'Payments', 'vi': 'Thanh toán'},
  'technical_issues': {'en': 'Technical Issues', 'vi': 'Vấn đề kỹ thuật'},
  'report_problem': {'en': 'Report a Problem', 'vi': 'Báo cáo sự cố'},
  'popular_articles': {'en': 'Popular Articles', 'vi': 'Bài viết phổ biến'},
  'reset_password_article': {'en': 'How to reset your password', 'vi': 'Cách đặt lại mật khẩu'},
  'privacy_settings_article': {'en': 'Managing your privacy settings', 'vi': 'Quản lý cài đặt quyền riêng tư'},
  'deactivate_account_article': {'en': 'How to deactivate your account', 'vi': 'Cách vô hiệu hóa tài khoản'},
  'login_issues_article': {'en': 'Troubleshooting login issues', 'vi': 'Khắc phục sự cố đăng nhập'},
  'feed_algorithm_article': {'en': 'Understanding your feed algorithm', 'vi': 'Hiểu thuật toán bảng tin của bạn'},
  'article_coming_soon': {'en': 'Article coming soon!', 'vi': 'Bài viết sắp ra mắt!'},
  'contact_us': {'en': 'Contact Us', 'vi': 'Liên hệ'},
  'chat_support': {'en': 'Chat Support', 'vi': 'Hỗ trợ trò chuyện'},
  'chat_support_coming': {'en': 'Chat support coming soon!', 'vi': 'Hỗ trợ trò chuyện sắp ra mắt!'},
  'email_support': {'en': 'Email Support', 'vi': 'Hỗ trợ qua Email'},
  'email_support_coming': {'en': 'Email support coming soon!', 'vi': 'Hỗ trợ qua email sắp ra mắt!'},
  'coming_soon_suffix': {'en': ' — coming soon!', 'vi': ' — sắp ra mắt!'},

  // Article bodies
  'reset_password_article_body': {
    'en': 'If you forgot your password, open the login screen and tap "Forgot password". Enter your email and we will send you a reset link. Open the link, choose a new password (at least 8 characters), and sign in again.',
    'vi': 'Nếu bạn quên mật khẩu, hãy mở màn hình đăng nhập và nhấn "Quên mật khẩu". Nhập email của bạn và chúng tôi sẽ gửi một liên kết đặt lại. Mở liên kết, chọn mật khẩu mới (ít nhất 8 ký tự) rồi đăng nhập lại.',
  },
  'privacy_settings_article_body': {
    'en': 'Go to Settings → Privacy & Security to control who can see your profile, email and friends list, and who can send you friend requests. You can also manage your blocked users list there.',
    'vi': 'Vào Cài đặt → Quyền riêng tư & Bảo mật để kiểm soát ai có thể xem trang cá nhân, email và danh sách bạn bè của bạn, cũng như ai có thể gửi lời mời kết bạn. Bạn cũng có thể quản lý danh sách người bị chặn tại đó.',
  },
  'deactivate_account_article_body': {
    'en': 'To deactivate your account, go to Settings → Personal Information and choose "Delete account". Your profile and posts will be hidden. Contact support if you want to restore your account later.',
    'vi': 'Để vô hiệu hóa tài khoản, vào Cài đặt → Thông tin cá nhân và chọn "Xóa tài khoản". Trang cá nhân và bài viết của bạn sẽ được ẩn đi. Liên hệ bộ phận hỗ trợ nếu sau này bạn muốn khôi phục tài khoản.',
  },
  'login_issues_article_body': {
    'en': 'Make sure your email and password are correct and your account email is verified. If you signed up but cannot log in, tap "Resend verification email" on the sign-up screen. Check your internet connection and try again.',
    'vi': 'Hãy đảm bảo email và mật khẩu chính xác và email tài khoản đã được xác thực. Nếu bạn đã đăng ký nhưng không đăng nhập được, hãy nhấn "Gửi lại email xác thực" ở màn hình đăng ký. Kiểm tra kết nối mạng và thử lại.',
  },
  'feed_algorithm_article_body': {
    'en': 'Your feed shows posts from your friends and people you follow, with the most recent posts first. Interacting with posts (likes, comments) and adding more friends helps you see more relevant content.',
    'vi': 'Bảng tin hiển thị bài viết từ bạn bè và những người bạn theo dõi, với các bài mới nhất hiển thị trước. Tương tác với bài viết (thích, bình luận) và kết bạn thêm sẽ giúp bạn thấy nội dung phù hợp hơn.',
  },

  // Topic bodies
  'getting_started_body': {
    'en': 'Welcome! Create your profile, add a photo, find friends through suggestions or search, and share your first post or story. Use the bottom dock to switch between feed, friends, messages and your profile.',
    'vi': 'Chào mừng bạn! Hãy tạo trang cá nhân, thêm ảnh, tìm bạn bè qua mục gợi ý hoặc tìm kiếm, và chia sẻ bài viết hoặc tin đầu tiên của bạn. Dùng thanh điều hướng dưới cùng để chuyển giữa bảng tin, bạn bè, tin nhắn và trang cá nhân.',
  },
  'privacy_safety_body': {
    'en': 'Control who can see your content and interact with you in Settings → Privacy & Security. You can block users, hide your email, and limit who can send friend requests. Report any post or user that violates our rules.',
    'vi': 'Kiểm soát ai có thể xem nội dung và tương tác với bạn trong Cài đặt → Quyền riêng tư & Bảo mật. Bạn có thể chặn người dùng, ẩn email và giới hạn ai có thể gửi lời mời kết bạn. Hãy báo cáo bất kỳ bài viết hay người dùng nào vi phạm quy định.',
  },
  'account_settings_body': {
    'en': 'Manage your name, bio and photos in Personal Information. Change your password, switch language, and choose light or dark theme from the Settings screen at any time.',
    'vi': 'Quản lý tên, tiểu sử và ảnh trong mục Thông tin cá nhân. Bạn có thể đổi mật khẩu, chuyển ngôn ngữ và chọn giao diện sáng hoặc tối trong màn hình Cài đặt bất cứ lúc nào.',
  },
  'payments_body': {
    'en': 'This app is completely free to use. There are no paid plans, subscriptions or in-app purchases. If you ever see a request for payment, do not provide your details and report it to support.',
    'vi': 'Ứng dụng này hoàn toàn miễn phí. Không có gói trả phí, đăng ký hay mua hàng trong ứng dụng. Nếu bạn thấy bất kỳ yêu cầu thanh toán nào, đừng cung cấp thông tin và hãy báo cho bộ phận hỗ trợ.',
  },
  'technical_issues_body': {
    'en': 'If something is not working, check your internet connection and update the app to the latest version. Closing and reopening the app fixes most temporary issues. If the problem continues, contact support with a description of what happened.',
    'vi': 'Nếu có gì đó không hoạt động, hãy kiểm tra kết nối mạng và cập nhật ứng dụng lên phiên bản mới nhất. Đóng và mở lại ứng dụng có thể khắc phục hầu hết sự cố tạm thời. Nếu vẫn lỗi, hãy liên hệ hỗ trợ kèm mô tả tình huống.',
  },
  'report_problem_body': {
    'en': 'To report a post or user, open the item and use the report option. For other problems, contact our support team by email. Please include details and screenshots so we can help you faster.',
    'vi': 'Để báo cáo một bài viết hoặc người dùng, hãy mở mục đó và dùng tùy chọn báo cáo. Với các vấn đề khác, hãy liên hệ đội hỗ trợ qua email. Vui lòng kèm chi tiết và ảnh chụp màn hình để chúng tôi hỗ trợ nhanh hơn.',
  },

  // Contact dialog
  'contact_support_desc': {
    'en': 'Reach our support team using the details below. We usually reply within 24 hours.',
    'vi': 'Liên hệ đội hỗ trợ của chúng tôi qua thông tin bên dưới. Chúng tôi thường phản hồi trong vòng 24 giờ.',
  },
  'support_email_value': {'en': 'support@shiku.social', 'vi': 'support@shiku.social'},
  'support_hours_label': {'en': 'Support hours', 'vi': 'Giờ hỗ trợ'},
  'support_hours_value': {'en': 'Mon–Fri, 9:00–18:00 (GMT+7)', 'vi': 'Thứ 2–6, 9:00–18:00 (GMT+7)'},
  'close': {'en': 'Close', 'vi': 'Đóng'},

  // ═══════════════════════════════════════════════
  // ABOUT APP SCREEN
  // ═══════════════════════════════════════════════
  'social_network': {'en': 'Social Network', 'vi': 'Mạng xã hội'},
  'connect_share_inspire': {'en': 'Connect. Share. Inspire.', 'vi': 'Kết nối. Chia sẻ. Truyền cảm hứng.'},
  'version': {'en': 'Version', 'vi': 'Phiên bản'},
  'build_number': {'en': 'Build Number', 'vi': 'Số bản dựng'},
  'developer': {'en': 'Developer', 'vi': 'Nhà phát triển'},
  'website': {'en': 'Website', 'vi': 'Trang web'},
  'privacy_policy': {'en': 'Privacy Policy', 'vi': 'Chính sách bảo mật'},
  'terms_of_service': {'en': 'Terms of Service', 'vi': 'Điều khoản dịch vụ'},
  'licenses': {'en': 'Licenses', 'vi': 'Giấy phép'},
  'acknowledgements': {'en': 'Acknowledgements', 'vi': 'Lời cảm ơn'},
  'rate_this_app': {'en': 'Rate This App', 'vi': 'Đánh giá ứng dụng'},
  'thank_you_support': {'en': 'Thank you for your support!', 'vi': 'Cảm ơn bạn đã ủng hộ!'},
  'copyright': {'en': '© 2026 Social Network. All rights reserved.', 'vi': '© 2026 Mạng xã hội. Mọi quyền được bảo lưu.'},
  'made_in_vietnam': {'en': 'Made with ❤️ in Vietnam', 'vi': 'Được tạo với ❤️ tại Việt Nam'},
};
