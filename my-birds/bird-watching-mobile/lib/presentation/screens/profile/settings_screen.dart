import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/photo_repository.dart';
import '../../../data/services/local_database.dart';
import '../../../config/dependency_injection.dart';

/// Screen for app settings and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings keys
  static const String _mapTypeKey = 'map_type';
  static const String _autoSyncKey = 'auto_sync';
  static const String _notificationsKey = 'notifications_enabled';

  // Settings values
  String _mapType = 'normal';
  bool _autoSync = true;
  bool _notificationsEnabled = true;
  int _cacheSize = 0;
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheSize();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mapType = prefs.getString(_mapTypeKey) ?? 'normal';
      _autoSync = prefs.getBool(_autoSyncKey) ?? true;
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    });
  }

  Future<void> _loadCacheSize() async {
    setState(() {
      _isLoadingCache = true;
    });

    try {
      final photoRepo = getIt<PhotoRepository>();
      final cacheSize = await photoRepo.getCacheSize();
      
      setState(() {
        _cacheSize = cacheSize;
        _isLoadingCache = false;
      });
    } catch (e) {
      print('[SettingsScreen Error] Failed to load cache size: $e');
      setState(() {
        _isLoadingCache = false;
      });
    }
  }

  Future<void> _saveMapType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapTypeKey, value);
    setState(() {
      _mapType = value;
    });
  }

  Future<void> _saveAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, value);
    setState(() {
      _autoSync = value;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached photos and observation data, except observations pending sync. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Clear photo cache
        final photoRepo = getIt<PhotoRepository>();
        await photoRepo.clearPhotoCache();

        // Clear database cache (preserves pending syncs)
        final localDb = getIt<LocalDatabase>();
        await localDb.clearCache();

        // Reload cache size
        await _loadCacheSize();

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Map Settings Section
          _buildSectionHeader('Map Settings'),
          _buildMapTypeSelector(),
          
          const Divider(height: 1),
          
          // Sync Settings Section
          _buildSectionHeader('Sync Settings'),
          _buildAutoSyncToggle(),
          
          const Divider(height: 1),
          
          // Notification Settings Section
          _buildSectionHeader('Notifications'),
          _buildNotificationsToggle(),
          
          const Divider(height: 1),
          
          // Storage Section
          _buildSectionHeader('Storage'),
          _buildCacheSizeDisplay(),
          _buildClearCacheButton(),
          
          const Divider(height: 1),
          
          // About Section
          _buildSectionHeader('About'),
          _buildAppVersion(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildMapTypeSelector() {
    return ListTile(
      leading: const Icon(Icons.map),
      title: const Text('Map Type'),
      subtitle: Text(_getMapTypeLabel(_mapType)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showMapTypeDialog(),
    );
  }

  String _getMapTypeLabel(String type) {
    switch (type) {
      case 'normal':
        return 'Normal';
      case 'satellite':
        return 'Satellite';
      case 'terrain':
        return 'Terrain';
      case 'hybrid':
        return 'Hybrid';
      default:
        return 'Normal';
    }
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Map Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Normal'),
              value: 'normal',
              groupValue: _mapType,
              onChanged: (value) {
                if (value != null) {
                  _saveMapType(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Satellite'),
              value: 'satellite',
              groupValue: _mapType,
              onChanged: (value) {
                if (value != null) {
                  _saveMapType(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Terrain'),
              value: 'terrain',
              groupValue: _mapType,
              onChanged: (value) {
                if (value != null) {
                  _saveMapType(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Hybrid'),
              value: 'hybrid',
              groupValue: _mapType,
              onChanged: (value) {
                if (value != null) {
                  _saveMapType(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoSyncToggle() {
    return SwitchListTile(
      secondary: const Icon(Icons.sync),
      title: const Text('Auto-Sync'),
      subtitle: const Text('Automatically sync observations when online'),
      value: _autoSync,
      onChanged: (value) => _saveAutoSync(value),
    );
  }

  Widget _buildNotificationsToggle() {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications),
      title: const Text('Enable Notifications'),
      subtitle: const Text('Receive notifications for sync status'),
      value: _notificationsEnabled,
      onChanged: (value) => _saveNotifications(value),
    );
  }

  Widget _buildCacheSizeDisplay() {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('Cache Size'),
      subtitle: _isLoadingCache
          ? const Text('Calculating...')
          : Text(_formatBytes(_cacheSize)),
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadCacheSize,
        tooltip: 'Refresh',
      ),
    );
  }

  Widget _buildClearCacheButton() {
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: Colors.red),
      title: const Text(
        'Clear Cache',
        style: TextStyle(color: Colors.red),
      ),
      subtitle: const Text('Remove cached photos and data'),
      onTap: _clearCache,
    );
  }

  Widget _buildAppVersion() {
    return const ListTile(
      leading: Icon(Icons.info_outline),
      title: Text('App Version'),
      subtitle: Text('1.0.0+1'),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
