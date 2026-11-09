import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _studentNo = TextEditingController();
  final _programme = TextEditingController(text: 'BDSAI');
  int _year = 1;
  bool _signup = false;
  bool _busy = false;
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _studentNo.dispose();
    _programme.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(repositoryProvider);
    try {
      if (_signup) {
        await repo.signUp(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          studentNumber: _studentNo.text.trim().isEmpty ? null : _studentNo.text.trim(),
          programme: _programme.text.trim(),
          yearOfStudy: _year,
        );
      } else {
        await repo.signIn(email: _email.text.trim(), password: _password.text);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(isDemoModeProvider);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(Brand.indigo, Brand.violet, _anim.value)!,
                Color.lerp(Brand.violet, Brand.coral, _anim.value)!,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 920 : 460),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _Hero()),
                            const SizedBox(width: 40),
                            Expanded(child: _card(context, demo)),
                          ],
                        )
                      : Column(
                          children: [
                            _Hero(compact: true),
                            const SizedBox(height: 24),
                            _card(context, demo),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, bool demo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_signup ? 'Create your account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  demo
                      ? 'Demo mode: any email and password work. Use an email containing "staff" to see staff tools.'
                      : 'Sign in with your university email.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                if (_signup) ...[
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _studentNo,
                          decoration: const InputDecoration(labelText: 'Student no.', prefixIcon: Icon(Icons.badge_outlined)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _programme,
                          decoration: const InputDecoration(labelText: 'Programme', prefixIcon: Icon(Icons.school_outlined)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Year of study', prefixIcon: Icon(Icons.timeline_rounded)),
                    items: [for (var y = 1; y <= 5; y++) DropdownMenuItem(value: y, child: Text('Year $y'))],
                    onChanged: (v) => setState(() => _year = v ?? 1),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
                  validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_signup ? 'Create account' : 'Sign in'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _signup = !_signup),
                  child: Text(_signup ? 'I already have an account' : 'New here? Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 64 : 80,
          height: compact ? 64 : 80,
          decoration: BoxDecoration(
            color: white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: white.withValues(alpha: 0.4)),
          ),
          child: Icon(Icons.hub_rounded, color: white, size: compact ? 34 : 44),
        ),
        const SizedBox(height: 18),
        Text(AppConfig.appName,
            style: TextStyle(color: white, fontSize: compact ? 32 : 44, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(
          'Every answer a ${AppConfig.university} student needs — in one place.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(color: white.withValues(alpha: 0.92), fontSize: compact ? 15 : 18, height: 1.4),
        ),
        if (!compact) ...[
          const SizedBox(height: 28),
          for (final f in const [
            ('Where do I go?', 'Ask in plain words, get the right office.'),
            ('Track your requests', 'See every help ticket move from open to resolved.'),
            ('Find your people', 'Tutors, study groups and a first-year buddy.'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: white.withValues(alpha: 0.9), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: white.withValues(alpha: 0.92), fontSize: 15),
                        children: [
                          TextSpan(text: '${f.$1}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: f.$2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
