// Layar autentikasi: login, registrasi, mode tamu, dan akses cepat akun demo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/colors.dart';
import '../core/widgets/mascot.dart';
import '../core/widgets/tactile_button.dart';
import '../data/api/api_client.dart';
import '../state/providers.dart';
import '../state/session_controller.dart';
import 'labels.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Periksa ketersediaan server saat layar dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionControllerProvider.notifier).refreshServerInfo();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final controller = ref.read(sessionControllerProvider.notifier);
    final ok = _isRegister
        ? await controller.register(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _displayName.text.trim(),
          )
        : await controller.login(_email.text.trim(), _password.text);

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        final asyncError = ref.read(sessionControllerProvider);
        _error = asyncError.hasError ? describeError(asyncError.error!) : 'Gagal masuk.';
      }
    });
  }

  Future<void> _guest() async {
    setState(() => _busy = true);
    final ok = await ref.read(sessionControllerProvider.notifier).continueAsGuest();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        final asyncError = ref.read(sessionControllerProvider);
        _error = asyncError.hasError ? describeError(asyncError.error!) : 'Gagal masuk sebagai tamu.';
      }
    });
  }

  void _fillDemo() {
    setState(() {
      _isRegister = false;
      _email.text = 'demo@linguaquest.app';
      _password.text = 'demo12345';
    });
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverInfoProvider);
    final engineMode = ref.watch(engineModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: MascotWidget(size: 110, mood: MascotMood.happy),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'LinguaQuest',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _isRegister ? 'Buat akun barumu' : 'Selamat datang kembali!',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _ServerChip(server: server, engineMode: engineMode),
                    const SizedBox(height: 20),

                    if (_isRegister) ...[
                      TextFormField(
                        controller: _displayName,
                        textInputAction: TextInputAction.next,
                        decoration: _decoration('Nama tampilan', Icons.badge_outlined),
                        validator: (v) =>
                            (v == null || v.trim().length < 2) ? 'Nama minimal 2 karakter' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('Email', Icons.mail_outline_rounded),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _decoration('Kata sandi', Icons.lock_outline_rounded),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Kata sandi minimal 8 karakter' : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.heartRedLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.heartRedDark),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: AppColors.heartRedDark, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    TactileButton(
                      height: 52,
                      width: double.infinity,
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isRegister ? 'DAFTAR' : 'MASUK'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _isRegister = !_isRegister;
                                      _error = null;
                                    }),
                            child: Text(_isRegister
                                ? 'Sudah punya akun? Masuk'
                                : 'Belum punya akun? Daftar'),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TactileButton(
                            height: 46,
                            variant: ButtonVariant.outline,
                            onPressed: _busy ? null : _guest,
                            child: const Text('MAIN SEBAGAI TAMU',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TactileButton(
                            height: 46,
                            variant: ButtonVariant.secondary,
                            onPressed: _busy ? null : _fillDemo,
                            child: const Text('AKUN DEMO', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Server: ${server.online ? "online" : "offline"} • engine: $engineMode',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        isDense: true,
      );
}

class _ServerChip extends StatelessWidget {
  const _ServerChip({required this.server, required this.engineMode});

  final ServerInfo server;
  final String engineMode;

  @override
  Widget build(BuildContext context) {
    final online = server.online;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: online ? AppColors.primaryGreenLight : AppColors.heartRedLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 20,
            color: online ? AppColors.primaryGreenDark : AppColors.heartRedDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              online
                  ? 'Server aktif • DB ${server.database} • Redis ${server.redis} • Rust ${engineMode == "rust-ffi" ? "FFI" : "fallback"}'
                  : server.message,
              style: TextStyle(
                fontSize: 11,
                color: online ? AppColors.primaryGreenDark : AppColors.heartRedDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Membuka layar AuthView dari mana pun (dipakai shell untuk tombol keluar).
Future<void> showAuthView(BuildContext context) async {
  await Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AuthView()),
  );
}

/// Ekspor untuk pengujian.
ApiException debugApiError(String detail) =>
    ApiException(statusCode: 400, code: 'DEBUG', title: 'Debug', detail: detail);
