import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectSite {
  final String id;
  final String name;
  final DateTime createdAt;

  ProjectSite({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProjectSite.fromJson(Map<String, dynamic> json) => ProjectSite(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSite &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LedgerEntry {
  final String id;
  final String siteId;
  final DateTime timestamp;
  final String voiceTranscript;
  final int? labourCount;
  final double? ownerAmount;
  final double? labourPaid;
  final String? note;

  LedgerEntry({
    required this.id,
    required this.siteId,
    required this.timestamp,
    required this.voiceTranscript,
    this.labourCount,
    this.ownerAmount,
    this.labourPaid,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'siteId': siteId,
        'timestamp': timestamp.toIso8601String(),
        'voiceTranscript': voiceTranscript,
        'labourCount': labourCount,
        'ownerAmount': ownerAmount,
        'labourPaid': labourPaid,
        'note': note,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: json['id'],
        siteId: json['siteId'],
        timestamp: DateTime.parse(json['timestamp']),
        voiceTranscript: json['voiceTranscript'] ?? '',
        labourCount: json['labourCount'],
        ownerAmount: (json['ownerAmount'] as num?)?.toDouble(),
        labourPaid: (json['labourPaid'] as num?)?.toDouble(),
        note: json['note'],
      );
}

class AppState extends ChangeNotifier {
  List<ProjectSite> _sites = [];
  List<LedgerEntry> _entries = [];
  ProjectSite? _activeSite;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  bool _isAllTime = false;
  bool _useAiParsing = false;
  List<String> _groqApiKeys = [];
  String _groqModel = 'llama-3.3-70b-versatile';

  List<ProjectSite> get sites => _sites;
  List<LedgerEntry> get entries => _entries;
  ProjectSite? get activeSite => _activeSite;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  bool get isAllTime => _isAllTime;
  bool get useAiParsing => _useAiParsing;
  List<String> get groqApiKeys => _groqApiKeys;
  String get groqApiKey => _groqApiKeys.isNotEmpty ? _groqApiKeys.first : '';
  String get groqModel => _groqModel;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _isAllTime = false;
    notifyListeners();
  }

  void setAllTime(bool allTime) {
    _isAllTime = allTime;
    notifyListeners();
  }

  List<LedgerEntry> get activeSiteEntries {
    if (_activeSite == null) return [];
    final filtered = _entries.where((e) => e.siteId == _activeSite!.id).toList();
    // Sort by timestamp descending
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  List<LedgerEntry> get activeSiteEntriesFiltered {
    final entries = activeSiteEntries;
    if (_isAllTime) return entries;
    return entries.where((e) {
      return e.timestamp.year == _selectedDate.year &&
             e.timestamp.month == _selectedDate.month &&
             e.timestamp.day == _selectedDate.day;
    }).toList();
  }

  // Active Site KPIs
  int get activeLabourCount {
    return activeSiteEntriesFiltered.fold(0, (sum, item) => sum + (item.labourCount ?? 0));
  }

  double get activeOwnerAmount {
    return activeSiteEntriesFiltered.fold(0.0, (sum, item) => sum + (item.ownerAmount ?? 0.0));
  }

  double get activeLabourPaid {
    return activeSiteEntriesFiltered.fold(0.0, (sum, item) => sum + (item.labourPaid ?? 0.0));
  }

  int get activeNotesCount {
    return activeSiteEntriesFiltered.where((e) => e.note != null && e.note!.isNotEmpty).length;
  }

  int get activeSiteDaysWorked {
    final entries = activeSiteEntries;
    final uniqueDays = entries.map((e) {
      return '${e.timestamp.year}-${e.timestamp.month}-${e.timestamp.day}';
    }).toSet();
    return uniqueDays.length;
  }

  AppState() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Sites
      final sitesJson = prefs.getString('sites');
      if (sitesJson != null) {
        final List<dynamic> decoded = json.decode(sitesJson);
        _sites = decoded.map((item) => ProjectSite.fromJson(item)).toList();
      } else {
        _sites = [];
      }

      // Load Entries
      final entriesJson = prefs.getString('entries');
      if (entriesJson != null) {
        final List<dynamic> decoded = json.decode(entriesJson);
        _entries = decoded.map((item) => LedgerEntry.fromJson(item)).toList();
      }

      // Load Active Site ID
      final activeSiteId = prefs.getString('activeSiteId');
      if (activeSiteId != null) {
        ProjectSite? foundSite;
        for (var s in _sites) {
          if (s.id == activeSiteId) {
            foundSite = s;
            break;
          }
        }
        _activeSite = foundSite ?? (_sites.isNotEmpty ? _sites.first : null);
      } else if (_sites.isNotEmpty) {
        _activeSite = _sites.first;
      }
      
      _useAiParsing = prefs.getBool('useAiParsing') ?? false;
      _groqApiKeys = prefs.getStringList('groqApiKeys') ?? [];
      // Migration fallback from single key:
      final oldKey = prefs.getString('groqApiKey');
      if (oldKey != null && oldKey.isNotEmpty && _groqApiKeys.isEmpty) {
        _groqApiKeys = [oldKey];
      }
      _groqModel = prefs.getString('groqModel') ?? 'llama-3.3-70b-versatile';
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final sitesJson = json.encode(_sites.map((s) => s.toJson()).toList());
      await prefs.setString('sites', sitesJson);

      final entriesJson = json.encode(_entries.map((e) => e.toJson()).toList());
      await prefs.setString('entries', entriesJson);

      if (_activeSite != null) {
        await prefs.setString('activeSiteId', _activeSite!.id);
      } else {
        await prefs.remove('activeSiteId');
      }

      await prefs.setBool('useAiParsing', _useAiParsing);
      await prefs.setStringList('groqApiKeys', _groqApiKeys);
      await prefs.setString('groqModel', _groqModel);
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  void setActiveSite(ProjectSite site) {
    _activeSite = site;
    _saveData();
    notifyListeners();
  }

  Future<void> addSite(String name) async {
    final newSite = ProjectSite(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _sites.add(newSite);
    _activeSite = newSite;
    await _saveData();
    notifyListeners();
  }

  Future<void> deleteSite(String id) async {
    _sites.removeWhere((s) => s.id == id);
    _entries.removeWhere((e) => e.siteId == id);
    
    if (_activeSite?.id == id) {
      _activeSite = _sites.isNotEmpty ? _sites.first : null;
    }
    
    await _saveData();
    notifyListeners();
  }

  Future<void> renameSite(String id, String newName) async {
    for (int i = 0; i < _sites.length; i++) {
      if (_sites[i].id == id) {
        _sites[i] = ProjectSite(
          id: _sites[i].id,
          name: newName,
          createdAt: _sites[i].createdAt,
        );
        if (_activeSite?.id == id) {
          _activeSite = _sites[i];
        }
        break;
      }
    }
    await _saveData();
    notifyListeners();
  }

  Future<void> addEntry(LedgerEntry entry) async {
    _entries.add(entry);
    await _saveData();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _saveData();
    notifyListeners();
  }

  // Clear all data
  Future<void> clearAll() async {
    _sites = [];
    _entries = [];
    _activeSite = null;
    await _saveData();
    notifyListeners();
  }

  Future<void> updateAiSettings({
    required bool useAiParsing,
    required List<String> groqApiKeys,
    required String groqModel,
  }) async {
    _useAiParsing = useAiParsing;
    _groqApiKeys = groqApiKeys.map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    _groqModel = groqModel;
    await _saveData();
    notifyListeners();
  }
}
