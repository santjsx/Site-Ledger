import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../speech_handler.dart';
import 'ledger_list_view.dart';
import 'voice_record_sheet.dart';
import 'settings_dialog.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF020617),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
            ),
          );
        }

        final activeSite = state.activeSite;

        return Scaffold(
          backgroundColor: const Color(0xFF020617), // Obsidian background
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B1329),
            elevation: 0,
            title: state.sites.isEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.home_work_rounded, color: Color(0xFF00F2FE), size: 20),
                      SizedBox(width: 8),
                      Text('సైట్ వాయిస్ లెడ్జర్', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  )
                : Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: const Color(0xFF0B1329),
                    ),
                    child: PopupMenuButton<ProjectSite>(
                      initialValue: activeSite,
                      tooltip: 'సైట్ మార్చండి',
                      offset: const Offset(0, 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_work_rounded, color: Color(0xFF00F2FE), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                activeSite?.name ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00F2FE), size: 20),
                          ],
                        ),
                      ),
                      onSelected: (site) {
                        state.setActiveSite(site);
                      },
                      itemBuilder: (context) {
                        return state.sites.map((site) {
                          final isSelected = site.id == activeSite?.id;
                          return PopupMenuItem<ProjectSite>(
                            value: site,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: isSelected ? const Color(0xFF00F2FE) : const Color(0xFF64748B),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    site.name,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_rounded, color: Color(0xFF00F2FE), size: 16),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF00F2FE)),
                tooltip: 'సైట్లు మార్చండి / తీసేయండి',
                onPressed: () => _showManageSitesSheet(context, state),
              ),
              IconButton(
                icon: const Icon(Icons.add_location_alt_outlined, color: Color(0xFF00F2FE)),
                tooltip: 'కొత్త సైట్ జోడించు',
                onPressed: () => _showAddSiteDialog(context, state),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Color(0xFF00F2FE)),
                tooltip: 'AI అమరికలు / సెట్టింగ్స్',
                onPressed: () => _showSettingsDialog(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => state.loadData(),
            color: const Color(0xFF00F2FE),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: state.sites.isEmpty
                    ? _buildEmptySitesOnboarding(context, state)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Site overview metadata
                          if (activeSite != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'సృష్టించబడిన తేదీ: ${DateFormat('dd MMM yyyy').format(activeSite.createdAt)}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                                if (state.isAllTime)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F2FE).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'మొత్తం కాలం',
                                      style: TextStyle(color: Color(0xFF00F2FE), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 16),

                          // Date Navigation Banner
                          _buildDateNavigationBanner(context, state),
                          const SizedBox(height: 16),

                          // Top Level Financial KPI Cards (2x2 Grid + Note Row)
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.4,
                            children: [
                              _buildKpiCard(
                                title: 'కార్మికుల సంఖ్య',
                                value: '${state.activeLabourCount}',
                                icon: Icons.people_outline_rounded,
                                color: const Color(0xFF00F2FE), // Cyan
                                subtitle: 'నమోదైన కార్మికులు',
                              ),
                              _buildKpiCard(
                                title: 'కార్మికులకు చెల్లింపులు',
                                value: formatter.format(state.activeLabourPaid),
                                icon: Icons.payments_outlined,
                                color: const Color(0xFF10B981), // Emerald
                                subtitle: 'చేల్లించిన నగదు', // Typo fix or keep Telugu
                              ),
                              _buildKpiCard(
                                title: 'ఓనర్ ఇచ్చిన పైసలు',
                                value: formatter.format(state.activeOwnerAmount),
                                icon: Icons.download_rounded,
                                color: const Color(0xFF8B5CF6), // Purple
                                subtitle: 'ఓనర్ పంపిన మొత్తం',
                              ),
                              _buildKpiCard(
                                title: 'చేతిలో ఉన్న నగదు',
                                value: formatter.format(state.activeOwnerAmount - state.activeLabourPaid),
                                icon: Icons.monetization_on_outlined,
                                color: (state.activeOwnerAmount - state.activeLabourPaid) >= 0
                                    ? const Color(0xFFF59E0B) // Amber
                                    : Colors.red.shade400, // Red for deficit
                                subtitle: (state.activeOwnerAmount - state.activeLabourPaid) >= 0
                                    ? 'మిగిలిన నిల్వ'
                                    : 'సొంతంగా పెట్టిన లోటు',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Notes & Activity Count Card
                          _buildFullWidthCard(
                            title: 'సైట్ రికార్డులు & గమనికలు',
                            value: '${state.activeSiteEntriesFiltered.length} రికార్డులు నమోదయ్యాయి',
                            icon: Icons.description_outlined,
                            color: const Color(0xFFEC4899), // Pink
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LedgerListView()),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Charts Section (Interactive Financial breakdown)
                          const Text(
                            'ఆర్థిక వివరాల విభజన',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          _buildChartCard(
                            state.activeLabourPaid,
                            state.activeOwnerAmount,
                            formatter,
                          ),

                          const SizedBox(height: 24),

                          // Navigation buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                  ),
                                  icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF00F2FE)),
                                  label: const Text(
                                    'అన్ని ఖర్చుల లిస్ట్ చూడండి',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LedgerListView()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ),
          ),
          bottomNavigationBar: state.sites.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    color: const Color(0xFF020617), // Obsidian background
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F2FE),
                          foregroundColor: const Color(0xFF020617),
                          elevation: 8,
                          shadowColor: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        icon: const Icon(Icons.mic_rounded, size: 28),
                        label: const Text(
                          'నోటితో చెప్పి రాయండి',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          if (activeSite == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ముందు ఒక సైట్ ని సెలెక్ట్ చేసుకోండి!')),
                            );
                            return;
                          }
                          _showVoiceRecordingSheet(context, activeSite.id, state.selectedDate);
                        },
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6), // Glassmorphic
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(double labourPaid, double ownerAmount, NumberFormat formatter) {
    final cashOnHand = ownerAmount - labourPaid;
    
    double labourPercent = 0.0;
    double balancePercent = 0.0;
    
    if (ownerAmount > 0) {
      if (cashOnHand >= 0) {
        labourPercent = labourPaid / ownerAmount;
        balancePercent = cashOnHand / ownerAmount;
      } else {
        labourPercent = 1.0;
        balancePercent = 0.0;
      }
    } else if (labourPaid > 0) {
      labourPercent = 1.0;
      balancePercent = 0.0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Donut Chart Custom Painter
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: DonutChartPainter(
                labourPercent: labourPercent,
                ownerPercent: balancePercent,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'అందిన బడ్జెట్',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          formatter.format(ownerAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Chart Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  color: const Color(0xFF10B981), // Emerald for labour
                  label: 'కూలీల జీతాలు',
                  value: formatter.format(labourPaid),
                  percent: ownerAmount > 0 ? '${(labourPercent * 100).toStringAsFixed(1)}%' : '0%',
                ),
                const SizedBox(height: 12),
                if (cashOnHand >= 0)
                  _buildLegendItem(
                    color: const Color(0xFF8B5CF6), // Purple for balance
                    label: 'మిగిలిన నిల్వ',
                    value: formatter.format(cashOnHand),
                    percent: ownerAmount > 0 ? '${(balancePercent * 100).toStringAsFixed(1)}%' : '0%',
                  )
                else
                  _buildLegendItem(
                    color: Colors.red.shade400, // Red for deficit
                    label: 'చేతి ఖర్చు (లోటు)',
                    value: formatter.format(-cashOnHand),
                    percent: 'లోటు',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
    required String percent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                  Text(
                    percent,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddSiteDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    final SpeechHandler speechHandler = SpeechHandler();
    bool isListening = false;
    String statusMessage = 'కొత్త సైట్ పేరు చెప్పడానికి మైక్ నొక్కండి';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            Future<void> startListening() async {
              final available = await speechHandler.initialize(
                onStatus: (status) {
                  if (status == 'listening') {
                    setState(() {
                      isListening = true;
                      statusMessage = 'వింటున్నాను... చెప్పండి';
                    });
                  } else if (status == 'notListening') {
                    setState(() {
                      isListening = false;
                      statusMessage = 'వినడం ఆగింది';
                    });
                  }
                },
                onError: (error) {
                  setState(() {
                    isListening = false;
                    statusMessage = 'లోపం: $error';
                  });
                },
              );

              if (available) {
                await speechHandler.startListening(
                  localeId: 'te-IN', // Telugu voice input for site names
                  onResult: (text) {
                    setState(() {
                      controller.text = text;
                    });
                  },
                  onDone: () {
                    setState(() {
                      isListening = false;
                    });
                  },
                );
              } else {
                setState(() {
                  statusMessage = 'మైక్ పని చేయడం లేదు';
                });
              }
            }

            Future<void> stopListening() async {
              await speechHandler.stopListening();
              setState(() {
                isListening = false;
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0B1329),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.white10),
              ),
              title: Row(
                children: const [
                  Icon(Icons.add_location_alt_outlined, color: Color(0xFF00F2FE)),
                  SizedBox(width: 12),
                  Text(
                    'కొత్త సైట్ జోడించు',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'సైట్ పేరు',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      hintText: 'సైట్ పేరు చెప్పండి లేదా రాయండి',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: isListening
                            ? IconButton(
                                icon: const Icon(Icons.stop_rounded, color: Colors.red, size: 24),
                                onPressed: stopListening,
                              )
                            : IconButton(
                                icon: const Icon(Icons.mic_rounded, color: Color(0xFF00F2FE), size: 24),
                                onPressed: startListening,
                              ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
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
                  Text(
                    statusMessage,
                    style: TextStyle(
                      color: isListening ? const Color(0xFF00F2FE) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isListening
                      ? null
                      : () {
                          speechHandler.cancelListening();
                          Navigator.pop(context);
                        },
                  child: const Text('వద్దు', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F2FE),
                    foregroundColor: const Color(0xFF020617),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: isListening
                      ? null
                      : () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            state.addSite(name);
                            speechHandler.cancelListening();
                            Navigator.pop(context);
                          }
                        },
                  child: const Text('సరే', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySitesOnboarding(BuildContext context, AppState state) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00F2FE).withValues(alpha: 0.05),
              border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.15)),
            ),
            child: const Icon(
              Icons.add_location_alt_outlined,
              size: 72,
              color: Color(0xFF00F2FE),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ఏ సైట్ కూడా లేదు',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'దయచేసి క్రింది బటన్ క్లిక్ చేసి, టైప్ చేయడం లేదా మాట్లాడడం ద్వారా మీ మొదటి సైట్‌ను జోడించండి.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F2FE),
              foregroundColor: const Color(0xFF020617),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text(
              'కొత్త సైట్‌ను జోడించు',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: () => _showAddSiteDialog(context, state),
          ),
        ],
      ),
    );
  }

  void _showVoiceRecordingSheet(BuildContext context, String siteId, DateTime initialDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return VoiceRecordSheet(siteId: siteId, initialDate: initialDate);
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  Widget _buildDateNavigationBanner(BuildContext context, AppState state) {
    final dateStr = DateFormat('dd MMM yyyy').format(state.selectedDate);
    final isToday = DateUtils.isSameDay(state.selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6), // Glassmorphic
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Segment selector for Daily vs All Time
              Row(
                children: [
                  _buildTabButton(
                    label: 'ఈరోజు',
                    isSelected: !state.isAllTime,
                    onTap: () => state.setAllTime(false),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'మొత్తం కాలం',
                    isSelected: state.isAllTime,
                    onTap: () => state.setAllTime(true),
                  ),
                ],
              ),
              // Today indicator button if not viewing all time
              if (!state.isAllTime && !isToday)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => state.setSelectedDate(DateTime.now()),
                  child: const Text(
                    'ఈరోజు',
                    style: TextStyle(color: Color(0xFF00F2FE), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (!state.isAllTime) ...[
            const Divider(color: Colors.white10, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF00F2FE), size: 20),
                  onPressed: () {
                    state.setSelectedDate(state.selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF00F2FE),
                                onPrimary: Color(0xFF020617),
                                surface: Color(0xFF0B1329),
                                onSurface: Colors.white,
                              ),
                              dialogTheme: const DialogThemeData(
                                backgroundColor: Color(0xFF0B1329),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        state.setSelectedDate(picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF94A3B8), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00F2FE), size: 20),
                  onPressed: () {
                    state.setSelectedDate(state.selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F2FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF020617) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showManageSitesSheet(BuildContext parentContext, AppState state) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<AppState>(
          builder: (consumerContext, appState, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), // Slate 900
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: Colors.white10),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Icon(Icons.edit_location_alt_outlined, color: Color(0xFF00F2FE)),
                      SizedBox(width: 12),
                      Text(
                        'సైట్లు మార్చండి / తీసేయండి',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.5,
                    ),
                    child: appState.sites.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'ఏ సైట్లు లేవు',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: appState.sites.length,
                            itemBuilder: (listContext, index) {
                              final site = appState.sites[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        site.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, color: Color(0xFF00F2FE), size: 20),
                                          onPressed: () {
                                            _showRenameSiteDialog(parentContext, appState, site);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                          onPressed: () {
                                            _showDeleteSiteConfirmation(parentContext, appState, site);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('ఓకే', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRenameSiteDialog(BuildContext context, AppState state, ProjectSite site) {
    final controller = TextEditingController(text: site.name);
    final SpeechHandler speechHandler = SpeechHandler();
    bool isListening = false;
    String statusMessage = 'కొత్త పేరు చెప్పడానికి మైక్ నొక్కండి';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            Future<void> startListening() async {
              final available = await speechHandler.initialize(
                onStatus: (status) {
                  if (status == 'listening') {
                    setState(() {
                      isListening = true;
                      statusMessage = 'వింటున్నాను... చెప్పండి';
                    });
                  } else if (status == 'notListening') {
                    setState(() {
                      isListening = false;
                      statusMessage = 'వినడం ఆగింది';
                    });
                  }
                },
                onError: (error) {
                  setState(() {
                    isListening = false;
                    statusMessage = 'లోపం: $error';
                  });
                },
              );

              if (available) {
                await speechHandler.startListening(
                  localeId: 'te-IN',
                  onResult: (text) {
                    setState(() {
                      controller.text = text;
                    });
                  },
                  onDone: () {
                    setState(() {
                      isListening = false;
                    });
                  },
                );
              }
            }

            Future<void> stopListening() async {
              await speechHandler.stopListening();
              setState(() {
                isListening = false;
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0B1329),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.white10),
              ),
              title: Row(
                children: const [
                  Icon(Icons.edit_location_alt_outlined, color: Color(0xFF00F2FE)),
                  SizedBox(width: 12),
                  Text('సైట్ పేరు మార్చండి', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'కొత్త పేరు',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: isListening
                            ? IconButton(
                                icon: const Icon(Icons.stop_rounded, color: Colors.red, size: 24),
                                onPressed: stopListening,
                              )
                            : IconButton(
                                icon: const Icon(Icons.mic_rounded, color: Color(0xFF00F2FE), size: 24),
                                onPressed: startListening,
                              ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
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
                  Text(
                    statusMessage,
                    style: TextStyle(
                      color: isListening ? const Color(0xFF00F2FE) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isListening
                      ? null
                      : () {
                          speechHandler.cancelListening();
                          Navigator.pop(context);
                        },
                  child: const Text('రద్దు చేయి', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F2FE),
                    foregroundColor: const Color(0xFF020617),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: isListening
                      ? null
                      : () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            state.renameSite(site.id, name);
                            speechHandler.cancelListening();
                            Navigator.pop(context);
                          }
                        },
                  child: const Text('మార్చండి', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteSiteConfirmation(BuildContext context, AppState state, ProjectSite site) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('సైట్ తీసేయాలా?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            '"${site.name}" సైట్ తీసేయాలా? ఇందులో ఉన్న అన్ని లెక్కలు కూడా డిలీట్ అయిపోతాయి.',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              child: const Text('వద్దు', style: TextStyle(color: Color(0xFF94A3B8))),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('తీసేయి', style: TextStyle(color: Colors.red)),
              onPressed: () {
                state.deleteSite(site.id);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

// Donut Chart Custom Painter
class DonutChartPainter extends CustomPainter {
  final double labourPercent;
  final double ownerPercent;

  DonutChartPainter({
    required this.labourPercent,
    required this.ownerPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 10.0;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, basePaint);

    if (labourPercent == 0 && ownerPercent == 0) return;

    // Draw Labour Arc
    final labourPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final ownerPaint = Paint()
      ..color = const Color(0xFF8B5CF6) // Purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final labourAngle = 2 * math.pi * labourPercent;
    final ownerAngle = 2 * math.pi * ownerPercent;

    if (labourPercent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        labourAngle,
        false,
        labourPaint,
      );
    }

    if (ownerPercent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + labourAngle,
        ownerAngle,
        false,
        ownerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.labourPercent != labourPercent || oldDelegate.ownerPercent != ownerPercent;
  }
}
