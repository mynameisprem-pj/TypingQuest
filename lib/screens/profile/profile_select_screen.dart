import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/profile_service.dart';
import '../../services/stats_service.dart';
import '../../services/progress_service.dart';
import '../home/home_screen.dart';

const List<String> _kAvatars = [
  '🧑','👦','👧','🧒','👨','👩','🧑‍💻','👨‍🎓','👩‍🎓',
  '🦁','🐯','🐼','🦊','🐻','🐸','🐧','🦄','🐉',
  '⚡','🌟','🎯','🚀','🎮','🏆','🎨','🎵','📚',
];
const List<String> _kClasses = [
  'Class 6','Class 7','Class 8','Class 9','Class 10','Teacher','Other',
];

enum _Mode { list, create, edit }

class ProfileSelectScreen extends StatefulWidget {
  /// switchMode = true when called from inside the app (drawer/settings).
  /// It pops instead of replacing with HomeScreen.
  final bool switchMode;
  const ProfileSelectScreen({super.key, this.switchMode = false});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  List<UserProfile> _profiles = [];
  bool _loading = true;
  _Mode _mode = _Mode.list;

  // Shared form fields
  final _nameCtrl = TextEditingController();
  String _selectedAvatar = '🧑';
  String _selectedClass = 'Class 8';
  UserProfile? _editTarget;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ProfileService().getProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = list;
        _loading = false;
        if (list.isEmpty) _mode = _Mode.create;
      });
    } catch (e) {
      // Corrupted data — clear it and fall back to create-profile screen
      await ProfileService().clearCorruptedData();
      if (!mounted) return;
      setState(() { _profiles = []; _loading = false; _mode = _Mode.create; });
    }
  }

  // ── Profile selection — reload services for new profile ─────────────────
  Future<void> _pick(UserProfile p) async {
    await ProfileService().setActiveProfile(p);
    await StatsService().init();
    await ProgressService().init();
    if (!mounted) return;
    if (widget.switchMode) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // ── Create ───────────────────────────────────────────────────────────────
  void _openCreate() {
    _nameCtrl.clear();
    _selectedAvatar = '🧑';
    _selectedClass = 'Class 8';
    _editTarget = null;
    setState(() => _mode = _Mode.create);
  }

  Future<void> _submitCreate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final p = await ProfileService().createProfile(name, _selectedClass, _selectedAvatar);
    if (!mounted) return;
    await _pick(p);
  }

  // ── Edit ─────────────────────────────────────────────────────────────────
  void _openEdit(UserProfile p) {
    _editTarget = p;
    _nameCtrl.text = p.name;
    _selectedAvatar = p.avatar;
    _selectedClass = p.className;
    setState(() => _mode = _Mode.edit);
  }

  Future<void> _submitEdit() async {
    final p = _editTarget;
    if (p == null || _nameCtrl.text.trim().isEmpty) return;
    final updated = UserProfile(
      id: p.id,
      name: _nameCtrl.text.trim(),
      className: _selectedClass,
      avatar: _selectedAvatar,
      createdAt: p.createdAt,
    );
    await ProfileService().updateProfile(updated);
    await _load();
    setState(() => _mode = _Mode.list);
  }

  // ── Delete ───────────────────────────────────────────────────────────────
  Future<void> _delete(UserProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${p.name}"?', style: AppTheme.heading(18)),
        content: Text(
          'All progress and stats for this profile will be permanently deleted.',
          style: AppTheme.body(14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.body(14, color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error, foregroundColor: Colors.white, elevation: 0),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: AppTheme.body(14, weight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ProfileService().deleteProfile(p.id);
    await _load();
  }

  void _back() {
    if (_mode != _Mode.list) {
      if (_profiles.isEmpty) {
        // Guest pressed cancel on create form — go back to home
        Navigator.pop(context, false);
      } else {
        setState(() => _mode = _Mode.list);
      }
    } else if (widget.switchMode || ProfileService().isGuest) {
      Navigator.pop(context, false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _CalmBg(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _mode == _Mode.list
                    ? _buildList()
                    : _buildForm(),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // LIST
  // ════════════════════════════════════════════════
  Widget _buildList() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(children: [
            // Logo
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Typing', style: AppTheme.heading(34, color: AppTheme.primary)),
              Text('Quest', style: AppTheme.heading(34, color: AppTheme.gold)),
            ]),
            const SizedBox(height: 4),
            Text('Mahadev Janta Secondary School',
                style: AppTheme.body(13, color: AppTheme.textSecondary)),
            const SizedBox(height: 36),

            // Section label
            Align(
              alignment: Alignment.centerLeft,
              child: Text('WHO IS PLAYING?',
                  style: AppTheme.body(10, color: AppTheme.textMuted)
                      .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            // Profile cards
            ..._profiles.map((p) {
              final isActive = ProfileService().activeProfile?.id == p.id;
              final canDelete = _profiles.length > 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProfileCard(
                  profile: p,
                  isActive: isActive,
                  onTap: () => _pick(p),
                  onEdit: () => _openEdit(p),
                  onDelete: canDelete ? () => _delete(p) : null,
                ),
              );
            }),

            const SizedBox(height: 14),

            // New profile
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: Text('New Profile', style: AppTheme.body(14, weight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.04),
                ),
                onPressed: _openCreate,
              ),
            ),

            if (widget.switchMode) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTheme.body(13, color: AppTheme.textSecondary)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // CREATE / EDIT FORM
  // ════════════════════════════════════════════════
  Widget _buildForm() {
    final isEdit = _mode == _Mode.edit;
    final canSubmit = _nameCtrl.text.trim().isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header row ──────────────────────────────────────────────
            Row(children: [
              // Show back arrow if there are real profiles to go back to,
              // OR if guest (always allow escape from the create form)
              if (_profiles.isNotEmpty || ProfileService().isGuest)
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded, size: 15, color: AppTheme.textSecondary),
                  ),
                ),
              if (_profiles.isNotEmpty || ProfileService().isGuest) const SizedBox(width: 12),
              Expanded(child: Text(isEdit ? 'Edit Profile' : 'New Profile', style: AppTheme.heading(22))),
            ]),
            const SizedBox(height: 4),
            Text(
              isEdit ? 'Update your name, avatar or class.' : 'Progress is saved separately per profile.',
              style: AppTheme.body(13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 26),

            // ── Avatar ──────────────────────────────────────────────────
            _Label('AVATAR'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _kAvatars.map((a) {
                final sel = _selectedAvatar == a;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryLight : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.cardBorder, width: sel ? 2 : 1),
                    ),
                    child: Center(child: Text(a, style: const TextStyle(fontSize: 22))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // ── Name ─────────────────────────────────────────────────────
            _Label('NAME'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: AppTheme.body(16),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_selectedAvatar, style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Class ─────────────────────────────────────────────────────
            _Label('CLASS'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _kClasses.map((c) {
                final sel = _selectedClass == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedClass = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryLight : AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.cardBorder, width: sel ? 2 : 1),
                    ),
                    child: Text(c, style: AppTheme.body(13,
                        color: sel ? AppTheme.primary : AppTheme.textPrimary,
                        weight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(isEdit ? Icons.check_rounded : Icons.person_add_outlined, size: 18),
                label: Text(
                  isEdit ? 'Save Changes' : 'Create & Start',
                  style: AppTheme.body(15, weight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.cardBorder,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canSubmit ? (isEdit ? _submitEdit : _submitCreate) : null,
              ),
            ),

            // Cancel / Maybe later — always visible so user is never trapped
            if (!isEdit) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _back,
                  child: Text(
                    ProfileService().isGuest ? 'Maybe Later' : 'Cancel',
                    style: AppTheme.body(13, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Profile card with edit + delete buttons ────────────────────────────────
class _ProfileCard extends StatefulWidget {
  final UserProfile profile;
  final bool isActive;
  final VoidCallback onTap, onEdit;
  final VoidCallback? onDelete;
  const _ProfileCard({
    required this.profile, required this.isActive,
    required this.onTap, required this.onEdit, this.onDelete,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.isActive ? AppTheme.primaryLight : _hovered ? Colors.white : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isActive ? AppTheme.primary : _hovered ? AppTheme.primaryDim : AppTheme.cardBorder,
            width: widget.isActive ? 2 : 1,
          ),
          boxShadow: _hovered || widget.isActive ? AppTheme.softShadow : null,
        ),
        child: Row(children: [
          // ── Main tap zone ────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(children: [
                  Text(widget.profile.avatar, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(widget.profile.name, style: AppTheme.heading(16)),
                      if (widget.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                          child: Text('Active', style: AppTheme.body(10, color: Colors.white, weight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(widget.profile.className, style: AppTheme.body(13, color: AppTheme.textSecondary)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMuted),
                ]),
              ),
            ),
          ),

          // ── Divider + action buttons ─────────────────────────────────
          Container(width: 1, height: 52, color: AppTheme.cardBorder),
          _IconAction(icon: Icons.edit_outlined, color: AppTheme.primary, tip: 'Edit', onTap: widget.onEdit),
          if (widget.onDelete != null) ...[
            Container(width: 1, height: 52, color: AppTheme.cardBorder),
            _IconAction(icon: Icons.delete_outline_rounded, color: AppTheme.error, tip: 'Delete', onTap: widget.onDelete!),
          ],
          const SizedBox(width: 6),
        ]),
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon; final Color color; final String tip; final VoidCallback onTap;
  const _IconAction({required this.icon, required this.color, required this.tip, required this.onTap});
  @override State<_IconAction> createState() => _IconActionState();
}
class _IconActionState extends State<_IconAction> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: Tooltip(
      message: widget.tip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 44, height: 52,
          decoration: BoxDecoration(
            color: _h ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(widget.icon, size: 18, color: _h ? widget.color : AppTheme.textMuted),
        ),
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String t;
  const _Label(this.t);
  @override
  Widget build(BuildContext ctx) => Text(t,
      style: AppTheme.body(10, color: AppTheme.textMuted)
          .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold));
}

// ── Calm pastel background ─────────────────────────────────────────────────
class _CalmBg extends StatelessWidget {
  const _CalmBg();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF2FF), Color(0xFFF0FDF9), Color(0xFFFFF7F0)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -50, left: -50, child: _Blob(140, AppTheme.primary, 0.08)),
        Positioned(top: 120, right: -30, child: _Blob(100, AppTheme.success, 0.07)),
        Positioned(bottom: 80, left: 30, child: _Blob(90, AppTheme.gold, 0.08)),
        Positioned(bottom: -30, right: 50, child: _Blob(130, AppTheme.lavender, 0.07)),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color; final double opacity;
  const _Blob(this.size, this.color, this.opacity);
  @override
  Widget build(BuildContext ctx) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
  );
}