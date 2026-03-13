import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final String className;
  final String avatar;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.className,
    required this.avatar,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'className': className,
    'avatar': avatar,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] ?? '',
    name: j['name'] ?? 'Unknown',
    className: j['className'] ?? 'Other',
    avatar: j['avatar'] ?? '🧑',
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] ?? 0),
  );
}

// ── Profile Service ────────────────────────────────────────────────────────
class ProfileService {
  static final ProfileService _i = ProfileService._();
  factory ProfileService() => _i;
  ProfileService._();

  // Nullable — NOT late. Safe even if init() threw or was skipped.
  SharedPreferences? _prefs;
  UserProfile? _activeProfile;

  UserProfile? get activeProfile => _activeProfile;
  bool get hasProfile => _activeProfile != null;

  /// True when the current profile is the auto-created guest (not a real student)
  bool get isGuest => _activeProfile?.id == 'guest';

  /// Called on startup when no saved profile exists.
  /// Creates a lightweight in-memory Guest profile — nothing written to storage.
  void ensureGuestProfile() {
    _activeProfile ??= UserProfile(
        id: 'guest',
        name: 'Guest',
        className: '',
        avatar: '👤',
        createdAt: DateTime.now(),
      );
  }

  /// Lazily ensures _prefs is ready — called by every method so they all
  /// work even if called before init() or if init() partially failed.
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> init() async {
    try {
      final prefs = await _getPrefs();
      final activeId = prefs.getString('active_profile_id');
      if (activeId != null) {
        final profiles = await getProfiles();
        try {
          _activeProfile = profiles.firstWhere((p) => p.id == activeId);
        } catch (_) {
          _activeProfile = profiles.isNotEmpty ? profiles.first : null;
        }
      }
    } on FormatException catch (e) {
      // Corrupted SharedPreferences data — wipe it so next launch is clean
      print('ProfileService: corrupted data detected, clearing. ($e)');
      await clearCorruptedData();
    } catch (e) {
      print('ProfileService init warning: $e');
    }
  }

  Future<List<UserProfile>> getProfiles() async {
    final prefs = await _getPrefs();
    final raw = prefs.getStringList('profiles') ?? [];
    final profiles = <UserProfile>[];
    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          profiles.add(UserProfile.fromJson(decoded));
        }
      } catch (e) {
        // Skip corrupted entries — one bad record won't crash the whole app
        print('ProfileService: skipping corrupted profile entry: $e');
      }
    }
    return profiles;
  }

  Future<UserProfile> createProfile(
      String name, String className, String avatar) async {
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      className: className,
      avatar: avatar,
      createdAt: DateTime.now(),
    );
    final profiles = await getProfiles();
    profiles.add(profile);
    await _saveProfiles(profiles);
    await setActiveProfile(profile);
    return profile;
  }

  Future<void> setActiveProfile(UserProfile profile) async {
    _activeProfile = profile;
    final prefs = await _getPrefs();
    await prefs.setString('active_profile_id', profile.id);
  }

  Future<void> deleteProfile(String id) async {
    final profiles = await getProfiles();
    profiles.removeWhere((p) => p.id == id);
    await _saveProfiles(profiles);
    if (_activeProfile?.id == id) {
      _activeProfile = profiles.isNotEmpty ? profiles.first : null;
      if (_activeProfile != null) {
        final prefs = await _getPrefs();
        await prefs.setString('active_profile_id', _activeProfile!.id);
      }
    }
  }

  Future<void> updateProfile(UserProfile updated) async {
    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    profiles[idx] = updated;
    await _saveProfiles(profiles);
    if (_activeProfile?.id == updated.id) _activeProfile = updated;
  }

  Future<void> _saveProfiles(List<UserProfile> profiles) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      'profiles',
      profiles.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  /// Wipes corrupted SharedPreferences data. Use if app is stuck.
  Future<void> clearCorruptedData() async {
    final prefs = await _getPrefs();
    await prefs.remove('profiles');
    await prefs.remove('active_profile_id');
    _activeProfile = null;
  }

  String get keyPrefix =>
      _activeProfile != null ? 'p_${_activeProfile!.id}_' : '';
}