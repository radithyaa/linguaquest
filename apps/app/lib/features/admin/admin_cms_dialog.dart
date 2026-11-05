// Admin CMS: menambah unit kurikulum baru ke server (`POST /v1/admin/units`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/api/api_client.dart';
import '../../state/session_controller.dart';
import '../../ui/labels.dart';

class AdminCmsDialog extends ConsumerStatefulWidget {
  const AdminCmsDialog({super.key, required this.onCourseAdded});

  final VoidCallback onCourseAdded;

  @override
  ConsumerState<AdminCmsDialog> createState() => _AdminCmsDialogState();
}

class _AdminCmsDialogState extends ConsumerState<AdminCmsDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _summary = TextEditingController();
  final _tips = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _summary.dispose();
    _tips.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _description.text.trim().isEmpty) {
      setState(() => _error = 'Judul dan deskripsi wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).createUnit(
            title: _title.text.trim(),
            description: _description.text.trim(),
            summary: _summary.text.trim(),
            grammarTips: _tips.text
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList(),
          );
      if (!mounted) return;
      widget.onCourseAdded();
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = describeError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: AppColors.jewelPurple, size: 28),
                  SizedBox(width: 8),
                  Text('Admin CMS - Tambah Unit',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: 'Judul Unit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Materi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _summary,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ringkasan Panduan Unit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tips,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Tips tata bahasa (satu per baris)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.heartRedDark, fontSize: 12)),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('BATAL'),
                  ),
                  const SizedBox(width: 8),
                  TactileButton(
                    height: 42,
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('SIMPAN UNIT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
