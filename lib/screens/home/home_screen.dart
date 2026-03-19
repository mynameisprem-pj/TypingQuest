import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/profile_service.dart';
import '../../services/sound_service.dart';
import '../../services/achievements_service.dart';
import '../../widgets/achievement_toast.dart';
import '../solo/difficulty_screen.dart';
import '../lan/lan_menu_screen.dart';
import '../lessons/lessons_home_screen.dart';
import '../timed/timed_challenge_screen.dart';
import '../custom/custom_text_screen.dart';
import '../stats/stats_screen.dart';
import '../achievements/achievements_screen.dart';
import '../profile/profile_select_screen.dart';
import '../fun/fun_hub_screen.dart';
import 'falling_words_game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    AchievementsService().onUnlock = (ach) {
      if (mounted) {
        SoundService().playAchievement();
        showAchievementToast(context, ach);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileService().activeProfile;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,

      // ── App Bar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('TQ', style: AppTheme.heading(14, color: AppTheme.primary)),
          ),
          const SizedBox(width: 10),
          Text('TypingQuest', style: AppTheme.heading(17, color: AppTheme.textPrimary)),
        ]),
        actions: [
          // Profile avatar / guest badge
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () async {
                  final switched = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => const ProfileSelectScreen(switchMode: true)));
                  if (switched == true && mounted) setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ProfileService().isGuest
                        ? AppTheme.gold.withValues(alpha: 0.12)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ProfileService().isGuest
                          ? AppTheme.gold.withValues(alpha: 0.5)
                          : AppTheme.cardBorder,
                    ),
                  ),
                  child: Row(children: [
                    Text(profile.avatar, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 5),
                    Text(
                      ProfileService().isGuest ? 'Guest' : profile.name,
                      style: AppTheme.body(12,
                          color: ProfileService().isGuest
                              ? AppTheme.gold
                              : AppTheme.textSecondary),
                    ),
                  ]),
                ),
              ),
            ),
          // Settings icon
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary, size: 22),
            tooltip: 'Settings',
            onPressed: () => _openSettings(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),

      // ── Navigation Drawer ────────────────────────────────────────────────
      drawer: _buildDrawer(context),

      // ── Body ────────────────────────────────────────────────────────────
      body: Column(
        children: [
          // Guest banner — only shown when no real profile exists
          if (ProfileService().isGuest) _GuestBanner(onCreateProfile: () async {
            final created = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => const ProfileSelectScreen()));
            if (created == true && mounted) setState(() {});
          }),
          const Expanded(child: FallingWordsGame()),
        ],
      ),
    );
  }

  // ── Drawer ───────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final profile = ProfileService().activeProfile;

    return Drawer(
      child: Container(
        color: AppTheme.surface,
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20, right: 20, bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.primaryLight],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('TQ', style: AppTheme.heading(20, color: AppTheme.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text('TypingQuest', style: AppTheme.heading(22, color: AppTheme.textPrimary)),
                  if (profile != null && !ProfileService().isGuest) ...[
                    const SizedBox(height: 4),
                    Text('${profile.avatar}  ${profile.name}  ·  ${profile.className}',
                        style: AppTheme.body(13, color: AppTheme.textSecondary)),
                  ],
                  if (ProfileService().isGuest) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final created = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => const ProfileSelectScreen()));
                        if (created == true && mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.person_add_outlined, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text('Create Profile to save progress',
                              style: AppTheme.body(12, color: AppTheme.primary)),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection('PRACTICE'),
                  _DrawerItem(icon: Icons.grid_view_rounded,    label: 'Solo Practice',   subtitle: '300 levels',       color: AppTheme.primary,   onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DifficultyScreen())); }),
                  _DrawerItem(icon: Icons.timer_outlined,       label: 'Timed Challenge', subtitle: '1 · 2 · 5 minutes', color: AppTheme.gold,       onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TimedChallengeScreen())); }),
                  _DrawerItem(icon: Icons.school_outlined,      label: 'Lessons',         subtitle: '6 courses',        color: AppTheme.success,    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonsHomeScreen())); }),
                  _DrawerItem(icon: Icons.edit_outlined,        label: 'Custom Text',     subtitle: 'Your own text',    color: AppTheme.lavender,   onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomTextScreen())); }),

                  const Divider(height: 24, indent: 16, endIndent: 16),
                  _DrawerSection('COMPETE'),
                  _DrawerItem(icon: Icons.lan_outlined,         label: 'LAN Race',        subtitle: 'School network',   color: const Color(0xFFFF6B35), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LanMenuScreen())); }),

                  const Divider(height: 24, indent: 16, endIndent: 16),
                  _DrawerSection('LEARN WITH FUN'),
                  _DrawerItem(icon: Icons.sports_esports_rounded, label: 'Game Hub',      subtitle: 'Space Shooter + more', color: const Color(0xFF00E5FF), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FunHubScreen())); }),

                  const Divider(height: 24, indent: 16, endIndent: 16),
                  _DrawerSection('MY PROGRESS'),
                  _DrawerItem(icon: Icons.bar_chart_rounded,    label: 'Stats',           subtitle: 'WPM history',      color: const Color(0xFF4FC3F7), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())); }),
                  _DrawerItem(icon: Icons.emoji_events_outlined, label: 'Achievements',   subtitle: '${AchievementsService().totalUnlocked}/${AchievementsService().total} unlocked', color: AppTheme.gold, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())); }),

                  const Divider(height: 24, indent: 16, endIndent: 16),
                  _DrawerItem(icon: Icons.people_outline,       label: 'Switch Profile',  subtitle: 'Change student',   color: AppTheme.lavender,   onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSelectScreen(switchMode: true))); }),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Learn with fun 😎',
                style: AppTheme.body(11, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings bottom sheet ─────────────────────────────────────────────────
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

// ── Drawer helpers ─────────────────────────────────────────────────────────
class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: Text(label, style: AppTheme.body(10, color: AppTheme.textMuted).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
  );
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withValues(alpha: 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.label, style: AppTheme.body(14, color: AppTheme.textPrimary, weight: FontWeight.w600)),
            Text(widget.subtitle, style: AppTheme.body(11, color: AppTheme.textSecondary)),
          ])),
          Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 13),
        ]),
      ),
    ),
  );
}

// ── Settings sheet ─────────────────────────────────────────────────────────
class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SoundService().enabled;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileService().activeProfile;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),

          Text('Settings', style: AppTheme.heading(20, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),

          // Profile
          if (profile != null) ...[
            _SettingLabel('ACCOUNT'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(children: [
                Text(profile.avatar, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile.name, style: AppTheme.body(15, weight: FontWeight.w600)),
                  Text(profile.className, style: AppTheme.body(12, color: AppTheme.textSecondary)),
                ])),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSelectScreen(switchMode: true)));
                  },
                  child: Text('Switch', style: AppTheme.body(13, color: AppTheme.primary)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          _SettingLabel('AUDIO'),
          const SizedBox(height: 8),
          _SettingRow(
            icon: _soundEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            iconColor: _soundEnabled ? AppTheme.primary : AppTheme.textMuted,
            title: 'Sound Effects',
            subtitle: 'Key clicks, errors, level complete',
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (v) async {
                await SoundService().setEnabled(v);
                setState(() => _soundEnabled = v);
              },
            ),
          ),
          const SizedBox(height: 20),

          _SettingLabel('APP'),
          // const SizedBox(height: 8),
          // _SettingRow(
          //   icon: Icons.school_outlined,
          //   iconColor: AppTheme.primary,
          //   title: 'School',
          //   subtitle: 'Mahadev Janta Secondary School',
          // ),
          const SizedBox(height: 6),
          _SettingRow(
            icon: Icons.info_outline,
            iconColor: AppTheme.textSecondary,
            title: 'Version',
            subtitle: 'TypingQuest v1.0.0',
          ),
        ],
      ),
      )
    );
  }
}

// ── Guest Banner ──────────────────────────────────────────────────────────────
class _GuestBanner extends StatelessWidget {
  final VoidCallback onCreateProfile;
  const _GuestBanner({required this.onCreateProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: AppTheme.gold.withValues(alpha: 0.25))),
      ),
      child: Row(children: [
        const Text('👤', style: TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Browsing as Guest — progress won\'t be saved',
            style: AppTheme.body(12, color: const Color.fromARGB(255, 45, 190, 52)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onCreateProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 187, 67, 75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Create Profile',
              style: AppTheme.body(11,
                  color: const Color.fromARGB(255, 255, 255, 255), weight: FontWeight.bold),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  final String t;
  const _SettingLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: AppTheme.body(10, color: AppTheme.textMuted).copyWith(letterSpacing: 2, fontWeight: FontWeight.bold));
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Widget? trailing;
  const _SettingRow({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.cardBorder),
    ),
    child: Row(children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.body(14, weight: FontWeight.w600)),
        Text(subtitle, style: AppTheme.body(11, color: AppTheme.textSecondary)),
      ])),
      ?trailing,
    ]),
  );
}