import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/sensor_data.dart';
import '../../domain/repositories/repositories.dart';

class SystemProvider extends ChangeNotifier {
  final SystemRepository _systemRepo;
  StreamSubscription<SystemStatus>? _sub;

  SystemStatus? _systemStatus;
  List<BackupRecord> _backups = [];

  SystemProvider({required SystemRepository systemRepo})
      : _systemRepo = systemRepo {
    _sub = _systemRepo.statusStream.listen((s) {
      _systemStatus = s;
      notifyListeners();
    });
    _loadBackups();
  }

  bool get isConnected => _systemStatus?.isConnected ?? true;
  DateTime get lastUpdated => _systemStatus?.lastSeen ?? DateTime.now();
  String get connectionLabel => isConnected ? 'LIVE' : 'OFFLINE';
  List<BackupRecord> get backups => _backups;

  Future<void> _loadBackups() async {
    _backups = await _systemRepo.getBackups();
    notifyListeners();
  }

  Future<BackupRecord> createBackup() async {
    final rec = await _systemRepo.createBackup();
    _backups = await _systemRepo.getBackups();
    notifyListeners();
    return rec;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _systemRepo.dispose();
    super.dispose();
  }
}
