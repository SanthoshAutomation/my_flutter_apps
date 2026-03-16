import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('com.example.sound_profile/audio');

// ─────────────────────────── Model ───────────────────────────

enum RingerMode { silent, vibrate, normal }

class SoundProfile {
  final String id;
  final String name;
  final String icon;
  final RingerMode ringerMode;
  final int ringtoneVolume; // 0–100 %
  final int mediaVolume;
  final int notificationVolume;
  final int alarmVolume;
  /// Controls the global "Use vibration & haptics" system toggle (VIBRATE_ON).
  /// On Motorola Android 15 this is the switch under Settings → Sound &
  /// Vibration → Vibration & haptics that was previously toggled manually.
  final bool hapticEnabled;

  const SoundProfile({
    required this.id,
    required this.name,
    required this.icon,
    required this.ringerMode,
    required this.ringtoneVolume,
    required this.mediaVolume,
    required this.notificationVolume,
    required this.alarmVolume,
    required this.hapticEnabled,
  });

  SoundProfile copyWith({
    String? id,
    String? name,
    String? icon,
    RingerMode? ringerMode,
    int? ringtoneVolume,
    int? mediaVolume,
    int? notificationVolume,
    int? alarmVolume,
    bool? hapticEnabled,
  }) =>
      SoundProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        ringerMode: ringerMode ?? this.ringerMode,
        ringtoneVolume: ringtoneVolume ?? this.ringtoneVolume,
        mediaVolume: mediaVolume ?? this.mediaVolume,
        notificationVolume: notificationVolume ?? this.notificationVolume,
        alarmVolume: alarmVolume ?? this.alarmVolume,
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'ringerMode': ringerMode.index,
        'ringtoneVolume': ringtoneVolume,
        'mediaVolume': mediaVolume,
        'notificationVolume': notificationVolume,
        'alarmVolume': alarmVolume,
        'hapticEnabled': hapticEnabled,
      };

  factory SoundProfile.fromJson(Map<String, dynamic> j) => SoundProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: (j['icon'] as String?) ?? '🔔',
        ringerMode: RingerMode.values[j['ringerMode'] as int],
        ringtoneVolume: j['ringtoneVolume'] as int,
        mediaVolume: j['mediaVolume'] as int,
        notificationVolume: j['notificationVolume'] as int,
        alarmVolume: j['alarmVolume'] as int,
        // Default: vibrate mode → haptics on; silent → off; normal → on
        hapticEnabled: j['hapticEnabled'] as bool? ??
            (RingerMode.values[j['ringerMode'] as int] != RingerMode.silent),
      );
}

List<SoundProfile> _defaultProfiles() => const [
      SoundProfile(
        id: 'normal',
        name: 'Normal',
        icon: '🔔',
        ringerMode: RingerMode.normal,
        ringtoneVolume: 70,
        mediaVolume: 50,
        notificationVolume: 70,
        alarmVolume: 70,
        hapticEnabled: true,
      ),
      SoundProfile(
        id: 'office',
        name: 'Office',
        icon: '💼',
        ringerMode: RingerMode.vibrate,
        ringtoneVolume: 0,
        mediaVolume: 0,
        notificationVolume: 0,
        alarmVolume: 70,
        hapticEnabled: true, // enables VIBRATE_ON so phone actually vibrates
      ),
      SoundProfile(
        id: 'silent',
        name: 'Silent',
        icon: '🔇',
        ringerMode: RingerMode.silent,
        ringtoneVolume: 0,
        mediaVolume: 0,
        notificationVolume: 0,
        alarmVolume: 70,
        hapticEnabled: false,
      ),
    ];

// ─────────────────────────── App ───────────────────────────

void main() => runApp(const SoundProfileApp());

class SoundProfileApp extends StatelessWidget {
  const SoundProfileApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sound Profiles',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      );
}

// ─────────────────────────── Home Screen ───────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<SoundProfile> _profiles = [];
  int _activeIndex = 0;
  Map<String, dynamic>? _systemState;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfiles();
    _refreshSystemState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh state when returning from DND settings screen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshSystemState();
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sound_profiles');
    final savedIdx = prefs.getInt('active_profile_index') ?? 0;

    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => SoundProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _profiles = list;
        _activeIndex = savedIdx.clamp(0, list.length - 1);
        _loading = false;
      });
    } else {
      setState(() {
        _profiles = _defaultProfiles();
        _activeIndex = 0;
        _loading = false;
      });
      _saveProfiles();
    }
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_profiles.map((p) => p.toJson()).toList());
    await prefs.setString('sound_profiles', json);
    await prefs.setInt('active_profile_index', _activeIndex);
    // Sync to native SharedPreferences so the Quick Settings Tile can use them
    try {
      await _channel.invokeMethod('saveProfilesToNative', {
        'profilesJson': json,
        'activeIndex': _activeIndex,
      });
    } catch (_) {}
  }

  Future<void> _refreshSystemState() async {
    try {
      final state =
          await _channel.invokeMapMethod<String, dynamic>('getCurrentState');
      if (mounted) setState(() => _systemState = state);
    } catch (_) {}
  }

  Future<void> _applyProfile(int index) async {
    final p = _profiles[index];
    try {
      await _channel.invokeMethod('applyProfile', {
        'ringerMode': p.ringerMode.index,
        'ringtoneVolume': p.ringtoneVolume,
        'mediaVolume': p.mediaVolume,
        'notificationVolume': p.notificationVolume,
        'alarmVolume': p.alarmVolume,
        'hapticEnabled': p.hapticEnabled,
      });
      setState(() => _activeIndex = index);
      await _saveProfiles();
      await _refreshSystemState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${p.icon} ${p.name} activated'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED' && mounted) _showDndDialog();
    }
  }

  void _showDndDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Silent mode requires Do Not Disturb access.\n\n'
          'Tap "Open Settings", then enable "Sound Profile" in the list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _channel.invokeMethod('requestDndPermission');
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showTileInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Quick Settings Tile'),
        content: const SingleChildScrollView(
          child: Text(
            'Add the Sound Profile tile to your notification panel:\n\n'
            '1. Swipe down twice to open Quick Settings\n'
            '2. Tap the ✏️ pencil (Edit) icon\n'
            '3. Find "Sound Profile" in the available tiles\n'
            '4. Drag it up into your active tiles area\n'
            '5. Tap the back arrow to confirm\n\n'
            'Once added, tap the tile to cycle through your '
            'profiles without opening the app!',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _editProfile(int index) async {
    final result = await showModalBottomSheet<SoundProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ProfileEditor(profile: _profiles[index]),
    );
    if (result != null) {
      setState(() => _profiles[index] = result);
      _saveProfiles();
    }
  }

  void _addProfile() async {
    final newProfile = SoundProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Profile',
      icon: '🎵',
      ringerMode: RingerMode.normal,
      ringtoneVolume: 70,
      mediaVolume: 50,
      notificationVolume: 70,
      alarmVolume: 70,
      hapticEnabled: true,
    );
    final result = await showModalBottomSheet<SoundProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ProfileEditor(profile: newProfile, isNew: true),
    );
    if (result != null) {
      setState(() => _profiles.add(result));
      _saveProfiles();
    }
  }

  void _deleteProfile(int index) {
    if (_profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last profile')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Delete "${_profiles[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _profiles.removeAt(index);
                if (_activeIndex >= _profiles.length) {
                  _activeIndex = _profiles.length - 1;
                }
              });
              _saveProfiles();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _modeColor(RingerMode m) => switch (m) {
        RingerMode.normal => Colors.green,
        RingerMode.vibrate => Colors.orange,
        RingerMode.silent => Colors.blueGrey,
      };

  IconData _modeIcon(RingerMode m) => switch (m) {
        RingerMode.normal => Icons.volume_up,
        RingerMode.vibrate => Icons.vibration,
        RingerMode.silent => Icons.volume_off,
      };

  String _modeLabel(RingerMode m) => switch (m) {
        RingerMode.normal => 'Normal',
        RingerMode.vibrate => 'Vibrate',
        RingerMode.silent => 'Silent',
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentMode = _systemState != null
        ? RingerMode.values[(_systemState!['ringerMode'] as int?) ?? 2]
        : null;
    final hasDnd = _systemState?['hasDndPermission'] as bool? ?? true;
    final hasWriteSettings = _systemState?['hasWriteSettings'] as bool? ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_queue_outlined),
            tooltip: 'Add Quick Settings Tile',
            onPressed: _showTileInstructions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh current state',
            onPressed: _refreshSystemState,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── System state banner ──
          if (currentMode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Material(
                color: _modeColor(currentMode).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _refreshSystemState,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(_modeIcon(currentMode),
                            color: _modeColor(currentMode)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current: ${_modeLabel(currentMode)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _modeColor(currentMode),
                                ),
                              ),
                              if (_systemState != null)
                                Text(
                                  'Ring ${_systemState!['ringtoneVolume']}%  '
                                  'Media ${_systemState!['mediaVolume']}%  '
                                  'Alarm ${_systemState!['alarmVolume']}%',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        if (!hasDnd)
                          GestureDetector(
                            onTap: () =>
                                _channel.invokeMethod('requestDndPermission'),
                            child: Tooltip(
                              message: 'Tap to grant DND access (needed for Silent mode)',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.amber.shade700, size: 18),
                                  const SizedBox(width: 4),
                                  Text('DND',
                                      style: TextStyle(
                                          color: Colors.amber.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // ── Write-settings permission banner ──
          // Without this permission the app cannot flip the global
          // "Use vibration & haptics" toggle automatically.
          if (!hasWriteSettings)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Material(
                color: Colors.deepOrange.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      _channel.invokeMethod('requestWriteSettingsPermission'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.phonelink_setup,
                            color: Colors.deepOrange.shade700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Grant "Modify system settings" so vibration '
                            'is toggled automatically. Tap to open settings.',
                            style: TextStyle(
                                color: Colors.deepOrange.shade800,
                                fontSize: 12),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.deepOrange.shade700, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Tap a profile to activate  •  ⋮ to edit or delete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // ── Profile grid ──
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.92,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _profiles.length,
              itemBuilder: (ctx, i) => _ProfileCard(
                profile: _profiles[i],
                isActive: i == _activeIndex,
                modeColor: _modeColor(_profiles[i].ringerMode),
                modeIcon: _modeIcon(_profiles[i].ringerMode),
                modeLabel: _modeLabel(_profiles[i].ringerMode),
                onTap: () => _applyProfile(i),
                onEdit: () => _editProfile(i),
                onDelete: () => _deleteProfile(i),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProfile,
        icon: const Icon(Icons.add),
        label: const Text('New Profile'),
      ),
    );
  }
}

// ─────────────────────────── Profile Card ───────────────────────────

class _ProfileCard extends StatelessWidget {
  final SoundProfile profile;
  final bool isActive;
  final Color modeColor;
  final IconData modeIcon;
  final String modeLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.modeColor,
    required this.modeIcon,
    required this.modeLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive ? modeColor.withAlpha(30) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? modeColor : cs.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(profile.icon, style: const TextStyle(fontSize: 30)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              dense: true,
                              contentPadding: EdgeInsets.zero)),
                      PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('Delete'),
                              dense: true,
                              contentPadding: EdgeInsets.zero)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? modeColor : null,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(modeIcon, size: 13, color: modeColor),
                  const SizedBox(width: 3),
                  Text(modeLabel,
                      style: TextStyle(fontSize: 12, color: modeColor)),
                ],
              ),
              const Spacer(),
              _MiniVolumeBars(profile: profile),
              const SizedBox(height: 8),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: modeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniVolumeBars extends StatelessWidget {
  final SoundProfile profile;
  const _MiniVolumeBars({required this.profile});

  @override
  Widget build(BuildContext context) {
    final bars = [
      ('🔔', profile.ringtoneVolume),
      ('🎵', profile.mediaVolume),
      ('⏰', profile.alarmVolume),
    ];
    return Column(
      children: bars.map((b) {
        final (label, pct) = b;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 4,
                    backgroundColor: Colors.grey.withAlpha(40),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 28,
                child: Text('$pct%',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 9)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────── Profile Editor ───────────────────────────

class ProfileEditor extends StatefulWidget {
  final SoundProfile profile;
  final bool isNew;
  const ProfileEditor(
      {super.key, required this.profile, this.isNew = false});

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late TextEditingController _nameCtrl;
  late String _icon;
  late RingerMode _ringerMode;
  late double _ringtone, _media, _notification, _alarm;
  late bool _hapticEnabled;

  static const _iconOptions = [
    '🔔', '💼', '🔇', '🏠', '🎵', '🌙',
    '🏃', '🎮', '📚', '✈️', '🏖️', '💤',
    '🍽️', '🚗', '🎬', '🏋️', '🧘', '🎤',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _icon = p.icon;
    _ringerMode = p.ringerMode;
    _ringtone = p.ringtoneVolume.toDouble();
    _media = p.mediaVolume.toDouble();
    _notification = p.notificationVolume.toDouble();
    _alarm = p.alarmVolume.toDouble();
    _hapticEnabled = p.hapticEnabled;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a profile name')),
      );
      return;
    }
    Navigator.pop(
      context,
      widget.profile.copyWith(
        name: name,
        icon: _icon,
        ringerMode: _ringerMode,
        ringtoneVolume: _ringtone.round(),
        mediaVolume: _media.round(),
        notificationVolume: _notification.round(),
        alarmVolume: _alarm.round(),
        hapticEnabled: _hapticEnabled,
      ),
    );
  }

  void _pickIcon() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Icon'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _iconOptions
              .map((ic) => GestureDetector(
                    onTap: () {
                      setState(() => _icon = ic);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ic == _icon
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                          child: Text(ic,
                              style: const TextStyle(fontSize: 26))),
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, sc) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    widget.isNew ? 'New Profile' : 'Edit Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable form
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.all(16),
                children: [
                  // Icon + Name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickIcon,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.outline),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                  child: Text(_icon,
                                      style:
                                          const TextStyle(fontSize: 30))),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Icon(Icons.edit,
                                    size: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Profile Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ringer mode selector
                  Text('Ringer Mode',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<RingerMode>(
                    segments: const [
                      ButtonSegment(
                          value: RingerMode.silent,
                          label: Text('Silent'),
                          icon: Icon(Icons.volume_off)),
                      ButtonSegment(
                          value: RingerMode.vibrate,
                          label: Text('Vibrate'),
                          icon: Icon(Icons.vibration)),
                      ButtonSegment(
                          value: RingerMode.normal,
                          label: Text('Normal'),
                          icon: Icon(Icons.volume_up)),
                    ],
                    selected: {_ringerMode},
                    onSelectionChanged: (s) =>
                        setState(() => _ringerMode = s.first),
                  ),
                  const SizedBox(height: 8),

                  // Hint below ringer mode
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: switch (_ringerMode) {
                      RingerMode.vibrate => _HintRow(
                          key: const ValueKey('v'),
                          icon: Icons.vibration,
                          color: Colors.orange,
                          text:
                              'Phone vibrates for calls & notifications. '
                              'Ringtone & notification volume sliders are disabled.',
                        ),
                      RingerMode.silent => _HintRow(
                          key: const ValueKey('s'),
                          icon: Icons.info_outline,
                          color: Colors.blueGrey,
                          text:
                              'No sound or vibration. Requires Do Not Disturb permission.',
                        ),
                      RingerMode.normal =>
                        const SizedBox.shrink(key: ValueKey('n')),
                    },
                  ),
                  const SizedBox(height: 12),

                  // Volume sliders
                  Text('Volume Settings',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  _VolumeSlider(
                    label: 'Ringtone',
                    icon: Icons.ring_volume,
                    value: _ringtone,
                    enabled: _ringerMode == RingerMode.normal,
                    onChanged: (v) => setState(() => _ringtone = v),
                  ),
                  _VolumeSlider(
                    label: 'Media',
                    icon: Icons.music_note,
                    value: _media,
                    onChanged: (v) => setState(() => _media = v),
                  ),
                  _VolumeSlider(
                    label: 'Notification',
                    icon: Icons.notifications_outlined,
                    value: _notification,
                    enabled: _ringerMode == RingerMode.normal,
                    onChanged: (v) => setState(() => _notification = v),
                  ),
                  _VolumeSlider(
                    label: 'Alarm',
                    icon: Icons.alarm,
                    value: _alarm,
                    onChanged: (v) => setState(() => _alarm = v),
                  ),
                  const SizedBox(height: 16),

                  // Haptic / vibration master toggle
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.vibration),
                    title: const Text('Use Vibration & Haptics'),
                    subtitle: const Text(
                      'Controls the global vibration switch '
                      '(Settings → Sound & Vibration → Vibration & haptics)',
                    ),
                    value: _hapticEnabled,
                    onChanged: (v) => setState(() => _hapticEnabled = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _HintRow(
      {super.key,
      required this.icon,
      required this.color,
      required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: TextStyle(color: color, fontSize: 13))),
          ],
        ),
      );
}

class _VolumeSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.icon,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            SizedBox(
                width: 88,
                child: Text(label, style: const TextStyle(fontSize: 13))),
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: enabled ? onChanged : null,
              ),
            ),
            SizedBox(
              width: 38,
              child: Text('${value.round()}%',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
}
