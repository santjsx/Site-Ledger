import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

class LedgerListView extends StatefulWidget {
  const LedgerListView({super.key});

  @override
  State<LedgerListView> createState() => _LedgerListViewState();
}

class _LedgerListViewState extends State<LedgerListView> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Labor', 'Financial', 'Notes'

  String _formatTeluguDateTime(DateTime date) {
    final months = ['జనవరి', 'ఫిబ్రవరి', 'మార్చి', 'ఏప్రిల్', 'మే', 'జూన్', 'జూలై', 'ఆగస్టు', 'సెప్టెంబరు', 'అక్టోబరు', 'నవంబరు', 'డిసెంబరు'];
    final timeStr = DateFormat('hh:mm a').format(date);
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final state = context.watch<AppState>();
    final activeSiteName = state.activeSite?.name ?? '';
    final entries = state.activeSiteEntries;

    // Apply filters
    final filteredEntries = entries.where((entry) {
      // Search filter
      final matchesSearch = entry.voiceTranscript.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (entry.note != null && entry.note!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      // Category filter
      switch (_selectedFilter) {
        case 'Labor':
          return (entry.labourCount != null && entry.labourCount! > 0) ||
              (entry.labourPaid != null && entry.labourPaid! > 0);
        case 'Financial':
          return (entry.labourPaid != null && entry.labourPaid! > 0) ||
              (entry.ownerAmount != null && entry.ownerAmount! > 0);
        case 'Notes':
          return entry.note != null && entry.note!.isNotEmpty;
        case 'All':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Obsidian
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1329),
        title: Text(
          activeSiteName.isEmpty ? 'ఖర్చుల చరిత్ర' : 'ఖర్చుల చరిత్ర - $activeSiteName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF00F2FE)),
            tooltip: 'ఫైల్ సేవ్ చేయి',
            onPressed: () => _exportCsv(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Header
          Container(
            color: const Color(0xFF0B1329),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'నోట్స్ లేదా మాటలను వెతకండి...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00F2FE), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00F2FE), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips (Scrollable horizontally to prevent squishing)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Labor', 'Financial', 'Notes'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      final Map<String, String> translations = {
                        'All': 'అన్నీ',
                        'Labor': 'కూలీలు',
                        'Financial': 'పైసలు / లెక్కలు',
                        'Notes': 'నోట్స్',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF00F2FE) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00F2FE) : Colors.white.withValues(alpha: 0.05),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Color(0xFF020617),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  translations[filter] ?? filter,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF020617) : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Ledger Timeline Feed
          Expanded(
            child: filteredEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return _buildLedgerCard(context, entry, formatter, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off_rounded, size: 64, color: Color(0xFF334155)),
          const SizedBox(height: 16),
          const Text(
            'ఇంకా ఏమీ రాయలేదు',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'మరోసారి వెతకండి'
                : 'మైక్ నొక్కి చెప్పండి, రాసుకుంటాము!',
            style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerCard(
    BuildContext context,
    LedgerEntry entry,
    NumberFormat formatter,
    AppState state,
  ) {
    // Determine which components to show based on selected filter
    final showLabour = _selectedFilter == 'All' || _selectedFilter == 'Labor';
    final showLabourPaid = _selectedFilter == 'All' || _selectedFilter == 'Labor' || _selectedFilter == 'Financial';
    final showOwnerSpent = _selectedFilter == 'All' || _selectedFilter == 'Financial';
    final showNote = _selectedFilter == 'All' || _selectedFilter == 'Notes';

    final hasLabour = showLabour && entry.labourCount != null && entry.labourCount! > 0;
    final hasLabourPaid = showLabourPaid && entry.labourPaid != null && entry.labourPaid! > 0;
    final hasOwnerSpent = showOwnerSpent && entry.ownerAmount != null && entry.ownerAmount! > 0;
    final hasNote = showNote && entry.note != null && entry.note!.isNotEmpty;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('ఈ వివరాలు తీసేయాలా?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'దీన్ని పూర్తిగా డిలీట్ చేయాలా?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: const Text('వద్దు', style: TextStyle(color: Color(0xFF94A3B8))),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text('తీసేయి', style: TextStyle(color: Colors.red.shade400)),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        state.deleteEntry(entry.id);
      },
      child: Card(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Timestamp & Delete Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTeluguDateTime(entry.timestamp),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  InkWell(
                    onTap: () => _confirmDelete(context, entry, state),
                    child: const Icon(Icons.close_rounded, color: Color(0xFF475569), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Voice Transcript Text
              Text(
                '"${entry.voiceTranscript}"',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),

              // Extracted Metrics Grid (Wrapped to support clean multi-line layouts)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasLabour)
                    _buildMetricBadge(
                      icon: Icons.people_rounded,
                      color: const Color(0xFF00F2FE),
                      label: '${entry.labourCount} మంది కూలీలు',
                    ),
                  if (entry.magaLabourCount != null && entry.magaLabourCount! > 0)
                    _buildMetricBadge(
                      icon: Icons.male_rounded,
                      color: const Color(0xFF3B82F6),
                      label: 'మగ: ${entry.magaLabourCount} మంది${entry.magaLabourPaid != null && entry.magaLabourPaid! > 0 ? ' (${formatter.format(entry.magaLabourPaid)})' : ''}',
                    ),
                  if (entry.aadaLabourCount != null && entry.aadaLabourCount! > 0)
                    _buildMetricBadge(
                      icon: Icons.female_rounded,
                      color: const Color(0xFFEC4899),
                      label: 'ఆడ: ${entry.aadaLabourCount} మంది${entry.aadaLabourPaid != null && entry.aadaLabourPaid! > 0 ? ' (${formatter.format(entry.aadaLabourPaid)})' : ''}',
                    ),
                  if (hasLabourPaid)
                    _buildMetricBadge(
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF10B981),
                      label: 'జీతాలు: ${formatter.format(entry.labourPaid)}',
                    ),
                  if (hasOwnerSpent)
                    _buildMetricBadge(
                      icon: Icons.download_rounded,
                      color: const Color(0xFF8B5CF6),
                      label: 'ఓనర్ ఇచ్చినవి: ${formatter.format(entry.ownerAmount)}',
                    ),
                ],
              ),

              // Note Row
              if (hasNote) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.description_rounded, color: Color(0xFFEC4899), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.note!,
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, LedgerEntry entry, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('ఈ వివరాలు తీసేయాలా?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'దీన్ని పూర్తిగా డిలీట్ చేయాలా?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('వద్దు', style: TextStyle(color: Color(0xFF94A3B8))),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('తీసేయి', style: TextStyle(color: Colors.red)),
            onPressed: () {
              state.deleteEntry(entry.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final entries = state.activeSiteEntries;

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ఫైల్ తయారు చేయడానికి ఏమీ లేదు')),
      );
      return;
    }

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Timestamp,Transcript,Labour Count,Labour Paid (INR),Maga Labour Count,Maga Labour Paid (INR),Aada Labour Count,Aada Labour Paid (INR),Owner Money Received (INR),Notes');

    for (var entry in entries) {
      final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp);
      final cleanTranscript = entry.voiceTranscript.replaceAll('"', '""');
      final cleanNote = (entry.note ?? '').replaceAll('"', '""');

      buffer.writeln(
        '$timeStr,"$cleanTranscript",${entry.labourCount ?? 0},${entry.labourPaid ?? 0.0},${entry.magaLabourCount ?? 0},${entry.magaLabourPaid ?? 0.0},${entry.aadaLabourCount ?? 0},${entry.aadaLabourPaid ?? 0.0},${entry.ownerAmount ?? 0.0},"$cleanNote"',
      );
    }

    final csvText = buffer.toString();

    // Show copy export dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B1329),
          title: Row(
            children: const [
              Icon(Icons.description, color: Color(0xFF00F2FE)),
              SizedBox(width: 8),
              Text('ఫైల్ రెడీ అయింది!', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'వాట్సాప్‌లో పంపడానికి కింద ఉన్న కోడ్‌ని కాపీ చేసుకోండి:',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csvText,
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('ఓకే', style: TextStyle(color: Color(0xFF94A3B8))),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F2FE),
                foregroundColor: const Color(0xFF020617),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('కాపీ చేయి', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('కాపీ అయింది!')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
