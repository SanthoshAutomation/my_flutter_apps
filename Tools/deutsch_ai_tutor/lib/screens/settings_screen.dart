import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storage;
  const SettingsScreen({super.key, required this.storage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = widget.storage.getApiKey() ?? '';
  }

  Future<void> _saveApiKey() async {
    await widget.storage.saveApiKey(_apiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key saved ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF533483)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await NotificationService.scheduleDailyReminder(
        hour: picked.hour,
        minute: picked.minute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Daily reminder set for ${picked.format(context)} ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Reset Progress?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete all your progress, lessons, and homework. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear all data
      final prefs = await _getPrefs();
      await prefs.clear();
      // Re-save API key
      await widget.storage.saveApiKey(_apiKeyController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress reset'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<dynamic> _getPrefs() async {
    // Access via storage
    return widget.storage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d1a),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('AI Configuration'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Claude API Key',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_isApiKeyVisible,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'sk-ant-...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isApiKeyVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(
                            () => _isApiKeyVisible = !_isApiKeyVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveApiKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF533483),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save API Key'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Notifications'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white54, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Daily Reminder',
                            style: TextStyle(color: Colors.white)),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        activeColor: const Color(0xFF533483),
                        onChanged: (v) async {
                          setState(() => _notificationsEnabled = v);
                          if (!v) {
                            await NotificationService.cancelAll();
                          } else {
                            await NotificationService.scheduleDailyReminder(
                              hour: _reminderTime.hour,
                              minute: _reminderTime.minute,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (_notificationsEnabled) ...[
                    const Divider(color: Colors.white12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time,
                          color: Colors.white54, size: 20),
                      title: const Text('Reminder Time',
                          style: TextStyle(color: Colors.white)),
                      trailing: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(
                            color: Color(0xFF533483),
                            fontWeight: FontWeight.bold),
                      ),
                      onTap: _pickReminderTime,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildInfoRow('App', 'DeutschMeister v2.0'),
                  const Divider(color: Colors.white12),
                  _buildInfoRow('AI Model', 'Claude Opus 4.6'),
                  const Divider(color: Colors.white12),
                  _buildInfoRow('Purpose', 'Learn German with AI'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Danger Zone'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetProgress,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Reset All Progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
