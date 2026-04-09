import 'package:flutter/material.dart';
import 'package:asbahani/services/download_manager.dart';

class DownloadAllScreen extends StatefulWidget {
  final String mushafType;
  final bool downloadAll;

  const DownloadAllScreen({
    super.key,
    required this.mushafType,
    required this.downloadAll,
  });

  @override
  State<DownloadAllScreen> createState() => _DownloadAllScreenState();
}

class _DownloadAllScreenState extends State<DownloadAllScreen> {
  double _progress = 0.0;
  String _statusText = 'جاري التحميل...';
  bool _error = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      if (mounted) {
        setState(() {
          _error = false;
          _completed = false;
        });
      }

      if (widget.downloadAll) {
        await DownloadManager.downloadAllPages(
          widget.mushafType,
          (current, totalCount, name) {
            if (mounted) {
              setState(() {
                _progress = current / totalCount;
                _statusText = '$name - $current / $totalCount';
              });
            }
          },
        );
      } else {
        await DownloadManager.downloadInitialPages(
          widget.mushafType,
          (current, totalCount, name) {
            if (mounted) {
              setState(() {
                _progress = current / totalCount;
                _statusText = '$name - $current / $totalCount';
              });
            }
          },
        );
      }

      if (mounted) {
        setState(() {
          _completed = true;
          _statusText = 'اكتمل التحميل ✓';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _statusText = 'خطأ في التحميل';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('تحميل المصحف'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _completed ? Icons.check_circle : Icons.download_rounded,
                  size: 80,
                  color: _completed ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'تحميل الصفحات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'amiri',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_error) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
                if (_completed) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
