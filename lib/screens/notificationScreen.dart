import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18191A), // Màu nền Facebook dark
      appBar: AppBar(
        title: const Text(
          "Thông báo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF242526),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.grey[800]),
        ),
      ),
      body: ListView(
        children: const [
          // Mục Yêu cầu theo dõi
          FollowRequestItem(),

          // Tin nổi bật
          SectionHeader(title: "Tin nổi bật"),
          NotificationItem(
            names: ["trantrandangiu_71", "rasbrryxrrt"],
            content: "đã chia sẻ ghi chú",
            time: "5 giờ",
          ),

          // 7 ngày qua
          SectionHeader(title: "7 ngày qua"),
          NotificationItem(
            names: ["im_prettypanh", "stackovermemes"],
            content: "đã chia sẻ 8 ảnh",
            time: "3 ngày",
          ),
          NotificationItem(
            names: ["im_prettypanh"],
            content: "vừa chia sẻ một bài viết",
            time: "5 ngày",
          ),
          NotificationItem(
            names: ["im_prettypanh", "stackovermemes"],
            content: "đã chia sẻ 6 ảnh",
            time: "5 ngày",
          ),

          // 30 ngày qua
          SectionHeader(title: "30 ngày qua"),
          NotificationItem(
            names: ["rasbrryxrtr", "amournamy"],
            content: "đã chia sẻ 5 ảnh",
            time: "1 tuần",
          ),
          NotificationItem(
            names: ["huyhn._.thuw", "rasbrryxrtr"],
            content: "đã chia sẻ 8 ảnh",
            time: "1 tuần",
          ),
          NotificationItem(
            names: ["rasbrryxrtr", "huyhn._.thuw"],
            content: "đã chia sẻ 7 ảnh",
            time: "1 tuần",
          ),
        ],
      ),
    );
  }
}

/// Tiêu đề từng nhóm (Tin nổi bật, 7 ngày qua,...)
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFB0B3B8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Item đặc biệt cho "Yêu cầu theo dõi"
class FollowRequestItem extends StatelessWidget {
  const FollowRequestItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF3A3B3C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              color: Color(0xFF2D88FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Yêu cầu theo dõi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Phê duyệt hoặc bỏ qua yêu cầu",
                  style: TextStyle(
                    color: Color(0xFFB0B3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Có thể thêm nút nếu muốn, nhưng theo mô tả chỉ có text
          // Nên giữ nguyên.
        ],
      ),
    );
  }
}

/// Item thông báo chung (có danh sách tên, nội dung, thời gian)
class NotificationItem extends StatelessWidget {
  final List<String> names;
  final String content;
  final String time;

  const NotificationItem({
    super.key,
    required this.names,
    required this.content,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    // Tạo chuỗi hiển thị tên: "tên1, tên2 và những người khác"
    String namesDisplay;
    if (names.length == 1) {
      namesDisplay = names.first;
    } else if (names.length == 2) {
      namesDisplay = "${names[0]} và ${names[1]}";
    } else {
      // Nếu nhiều hơn 2, lấy 2 tên đầu + "và những người khác"
      namesDisplay = "${names[0]}, ${names[1]} và những người khác";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (đại diện cho người đầu tiên, hoặc icon nhóm)
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[850],
            backgroundImage: NetworkImage(
              "https://i.pravatar.cc/150?img=${names.hashCode % 70}", // random theo tên
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFFE4E6EB),
                      fontSize: 15,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: namesDisplay,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: " $content"),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFFB0B3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Icon nhỏ bên phải (có thể là ảnh đại diện phụ, nhưng FB thường không có)
          // Để trống cho đơn giản
        ],
      ),
    );
  }
}