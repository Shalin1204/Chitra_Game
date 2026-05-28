import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/user_profile_service.dart';
import '../auth/providers/auth_provider.dart';

/// ProfileScreen operates in two modes:
///   [isEditMode = false] — first-time setup. No back button. "PLAY" navigates to home.
///   [isEditMode = true]  — opened from home top-right button. Shows back button. "SAVE" pops back.
class ProfileScreen extends ConsumerStatefulWidget {
  final bool isEditMode;
  const ProfileScreen({super.key, this.isEditMode = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String _selectedAvatar = '👽';
  int _highScore = 0;

  static const _avatars = [
    '👽', '🤖', '👻', '🤡', '🎃', '🐶', '🐱', '🦊', '🦁', '🐯',
    '🐼', '🐨', '🐸', '🦄', '🦖', '🐙', '👾', '🤠', '😎', '🤓',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('display_name') ?? '';
    final avatar = prefs.getString('avatar') ?? '👽';

    if (name.isNotEmpty) {
      _nameCtrl.text = name;
      _selectedAvatar = avatar;
      // Restore Riverpod state (in case app restarted)
      ref.read(currentUserIdProvider.notifier).state = name;
      ref.read(currentUserAvatarProvider.notifier).state = avatar;

      try {
        final profile = await ref.read(userProfileServiceProvider).fetchProfile(name);
        if (profile != null && profile.containsKey('highScore')) {
          _highScore = (profile['highScore'] as num).toInt();
        }
      } catch (_) {}

      if (!widget.isEditMode && mounted) {
        // First-launch path: profile already set → skip straight to home
        context.go(AppRoutes.home);
        return;
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a display name first!')),
      );
      return;
    }

    setState(() => _saving = true);

    // 1. SharedPreferences (local, instant)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', name);
    await prefs.setString('avatar', _selectedAvatar);

    // 2. Riverpod state
    ref.read(currentUserIdProvider.notifier).state = name;
    ref.read(currentUserAvatarProvider.notifier).state = _selectedAvatar;

    // 3. Firebase Firestore (async, fire-and-forget — don't block UI)
    ref.read(userProfileServiceProvider).saveProfile(
      displayName: name,
      avatar: _selectedAvatar,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (widget.isEditMode) {
      context.pop(); // Back to home
    } else {
      context.go(AppRoutes.home); // First time → navigate to home
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF191924),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF39FF14))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF191924),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // Back button row (edit mode only)
              if (widget.isEditMode)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1F3A30), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFFB09459), size: 20),
                    ),
                  ),
                ),
              if (widget.isEditMode) const SizedBox(height: 24),

              // PROFILE Title
              Text(
                'PROFILE',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 42,
                  color: const Color(0xFFFDE8C0),
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: const Color(0xFFD6A066).withValues(alpha: 0.8), blurRadius: 10),
                    Shadow(color: const Color(0xFFD6A066).withValues(alpha: 0.5), blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isEditMode
                    ? 'Edit your terminal identity.'
                    : 'Configure your terminal identity.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFFBAC0D0),
                ),
              ),
              if (_highScore > 0) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.1),
                    border: Border.all(color: const Color(0xFF39FF14)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🏆 HIGHEST SCORE: $_highScore',
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 12,
                      color: Color(0xFF39FF14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),

              // Main Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF041C1C),
                  border: Border.all(color: const Color(0xFF1F3A30), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Display Name ---
                    const Text(
                      'DISPLAY NAME',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 11,
                        color: Color(0xFFB09459),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      maxLength: 20,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        counterText: '',
                        contentPadding: EdgeInsets.only(bottom: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFB09459), width: 2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFB09459), width: 2),
                        ),
                        hintText: 'Neon_Drifter',
                        hintStyle: TextStyle(color: Color(0xFF4A5568), fontFamily: 'Courier'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Avatar Picker ---
                    const Text(
                      'SELECT AVATAR',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 11,
                        color: Color(0xFFB09459),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _avatars.length,
                      itemBuilder: (context, index) {
                        final a = _avatars[index];
                        final isSelected = _selectedAvatar == a;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = a),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF39FF14).withValues(alpha: 0.12)
                                  : const Color(0xFF062323),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF39FF14) : const Color(0xFF1F3A30),
                                width: isSelected ? 3 : 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: const Color(0xFF39FF14).withValues(alpha: 0.4), blurRadius: 12)]
                                  : null,
                            ),
                            child: Center(
                              child: Text(a, style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- Save / Play Button ---
                    _saving
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFFB09459),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : widget.isEditMode
                            ? OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF2E483B), width: 2),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                ),
                                onPressed: _saveProfile,
                                child: const Text(
                                  'SAVE PROFILE',
                                  style: TextStyle(
                                    fontFamily: 'PressStart2P',
                                    fontSize: 11,
                                    color: Color(0xFFB09459),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE2C28C), Color(0xFFC4985B)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE2C28C).withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _saveProfile,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 18),
                                      child: Center(
                                        child: Text(
                                          'PLAY',
                                          style: TextStyle(
                                            fontFamily: 'PressStart2P',
                                            fontSize: 18,
                                            color: Colors.black,
                                            letterSpacing: 3,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}