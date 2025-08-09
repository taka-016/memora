import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/managers/auth_manager.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.authManager,
    required this.email,
  });

  final AuthManager authManager;
  final String email;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isResending = false;
  bool _isChecking = false;
  String? _lastResendTime;
  DateTime? _lastResendDateTime;
  Timer? _cooldownTimer;
  Timer? _periodicCheckTimer;
  static const int _resendCooldownSeconds = 60;
  static const int _periodicCheckIntervalSeconds = 30;

  @override
  void initState() {
    super.initState();
    widget.authManager.addListener(_authStateListener);
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _periodicCheckTimer?.cancel();
    widget.authManager.removeListener(_authStateListener);
    super.dispose();
  }

  void _startPeriodicCheck() {
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: _periodicCheckIntervalSeconds),
      (_) => _checkEmailVerificationSilently(),
    );
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_canResend) {
        setState(() {});
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  Future<void> _checkEmailVerificationSilently() async {
    if (_isChecking) return;

    try {
      final isVerified = await widget.authManager.checkEmailVerified();
      if (isVerified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メール確認が完了しました！ログインしています...'),
            backgroundColor: Colors.green,
          ),
        );
        await widget.authManager.reloadUser();
      }
    } catch (e) {
      // サイレントチェックではエラーを表示しない
    }
  }

  void _authStateListener() {
    if (widget.authManager.state.isAuthenticated) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  bool get _canResend {
    if (_lastResendDateTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastResendDateTime!);
    return difference.inSeconds >= _resendCooldownSeconds;
  }

  int get _remainingCooldownSeconds {
    if (_lastResendDateTime == null) return 0;
    final now = DateTime.now();
    final difference = now.difference(_lastResendDateTime!);
    final remaining = _resendCooldownSeconds - difference.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_remainingCooldownSeconds秒後に再送信できます'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await widget.authManager.resendEmailVerification();
      final now = DateTime.now();
      setState(() {
        _lastResendTime = now.toString().substring(11, 19);
        _lastResendDateTime = now;
      });
      _startCooldownTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('確認メールを再送信しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('再送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final isVerified = await widget.authManager.checkEmailVerified();
      if (isVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('メール確認が完了しました！ログインしています...'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await widget.authManager.reloadUser();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('メール確認がまだ完了していません'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('確認に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メール確認'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              'メール確認が必要です',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.email} に確認メールを送信しました。',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'メール内のリンクをクリックして、メールアドレスを確認してください。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkEmailVerification,
                icon: _isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isChecking ? '確認中...' : '確認状態をチェック'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isResending || !_canResend
                    ? null
                    : _resendVerificationEmail,
                icon: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isResending
                      ? '送信中...'
                      : !_canResend
                      ? '確認メールを再送信 ($_remainingCooldownSeconds秒待機)'
                      : '確認メールを再送信',
                ),
              ),
            ),
            if (_lastResendTime != null) ...[
              const SizedBox(height: 16),
              Text(
                '最後の送信時刻: $_lastResendTime',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 32),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'メールが届かない場合',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 迷惑メールフォルダをご確認ください\n• メールアドレスが正しいかご確認ください\n• 数分お待ちいただいてから再送信してください',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
