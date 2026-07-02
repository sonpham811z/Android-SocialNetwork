import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/reportModel.dart';
import '../../services/postService.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final PostService _service = PostService();

  String _status = 'pending'; // 'pending' | '' (tất cả)
  bool _loading = false;
  String? _error;
  List<PostReportItem> _reports = [];
  String? _busyId; // id report/post đang xử lý

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getReports(status: _status);
      if (!mounted) return;
      setState(() => _reports = result.reports);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(String busyId, Future<bool> Function() action,
      String okMsg) async {
    setState(() => _busyId = busyId);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(okMsg)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Quản lý báo cáo',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    Widget chip(String label, String value) {
      final active = _status == value;
      return GestureDetector(
        onTap: () {
          if (_status == value) return;
          setState(() => _status = value);
          _load();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF2D88FF)
                : (isDark ? const Color(0xFF27272A) : AppTheme.slate100),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : (isDark ? AppTheme.slate300 : AppTheme.slate700))),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [chip('Chờ xử lý', 'pending'), chip('Tất cả', '')],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading && _reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_reports.isEmpty) {
      return const Center(
        child: Text('Không có báo cáo nào',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildReportCard(_reports[i], isDark),
      ),
    );
  }

  Widget _buildReportCard(PostReportItem r, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.slate900;
    final subColor = isDark ? AppTheme.slate400 : AppTheme.slate500;
    final busy = _busyId == r.id || _busyId == r.postId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? const Color(0xFF27272A) : AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lý do + trạng thái
          Row(
            children: [
              Expanded(
                child: Text(r.reason,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor)),
              ),
              _statusBadge(r),
            ],
          ),
          const SizedBox(height: 8),
          // Snapshot bài viết
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111214) : AppTheme.slate50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.postOwnerName ?? 'Người dùng'} · ${r.postType}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subColor),
                ),
                const SizedBox(height: 4),
                Text(
                  r.postContent,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
                if (r.postImageUrl != null &&
                    r.postImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(r.postImageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('Người báo cáo: ${r.reporterName ?? r.reporterId}',
              style: TextStyle(fontSize: 11, color: subColor)),
          const SizedBox(height: 10),
          // Hành động
          if (busy)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(6),
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            Row(
              children: [
                if (r.postIsHidden)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _runAction(r.postId,
                          () => _service.unhidePost(r.postId), 'Đã khôi phục bài'),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Khôi phục'),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _runAction(
                          r.postId, () => _service.hidePost(r.postId), 'Đã ẩn bài'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.visibility_off_outlined, size: 16),
                      label: const Text('Ẩn bài'),
                    ),
                  ),
                const SizedBox(width: 8),
                if (r.status == 'Pending')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _runAction(r.id,
                          () => _service.dismissReport(r.id), 'Đã bỏ qua báo cáo'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Bỏ qua'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(PostReportItem r) {
    Color color;
    String label;
    switch (r.status) {
      case 'Dismissed':
        color = Colors.grey;
        label = 'Đã bỏ qua';
        break;
      case 'ActionTaken':
        color = Colors.redAccent;
        label = 'Đã ẩn bài';
        break;
      default:
        color = Colors.orange;
        label = 'Chờ xử lý';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
