import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

class SitesDashboardView extends StatelessWidget {
  const SitesDashboardView({super.key});

  String _formatTeluguDate(DateTime date) {
    final months = [
      'జనవరి', 'ఫిబ్రవరి', 'మార్చి', 'ఏప్రిల్', 'మే', 'జూన్',
      'జూలై', 'ఆగస్టు', 'సెప్టెంబరు', 'అక్టోబరు', 'నవంబరు', 'డిసెంబరు'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Obsidian dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1329),
        elevation: 0,
        title: const Text(
          'అన్ని సైట్ల సమ్మరీ (All Sites Dashboard)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final sites = state.sites;
          final entries = state.entries;

          if (sites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_outlined, size: 64, color: Color(0xFF334155)),
                  const SizedBox(height: 16),
                  const Text(
                    'ఇంకా ఏ సైట్లు లేవు',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'కొత్త సైట్లను జోడించండి',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                  ),
                ],
              ),
            );
          }

          // Calculate overall metrics across all sites
          double totalReceived = 0.0;
          double totalSpent = 0.0;
          for (var entry in entries) {
            totalReceived += (entry.ownerAmount ?? 0.0);
            totalSpent += (entry.labourPaid ?? 0.0);
          }
          final totalCashOnHand = totalReceived - totalSpent;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overall Portfolio Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'మొత్తం పోర్ట్‌ఫోలియో (Total Portfolio)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${sites.length} సైట్లు',
                            style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'మొత్తం అందిన బడ్జెట్',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(totalReceived),
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'చేతిలో ఉన్న నిల్వ',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(totalCashOnHand),
                              style: TextStyle(
                                color: totalCashOnHand >= 0 ? const Color(0xFF10B981) : Colors.red.shade400,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'ప్రతి సైట్ వివరాలు (Individual Sites)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),

              // Individual Site Cards
              ...sites.map((site) {
                final siteEntries = entries.where((e) => e.siteId == site.id).toList();
                
                final double siteReceived = siteEntries.fold(0.0, (sum, e) => sum + (e.ownerAmount ?? 0.0));
                final double siteSpent = siteEntries.fold(0.0, (sum, e) => sum + (e.labourPaid ?? 0.0));
                final double siteCashOnHand = siteReceived - siteSpent;

                final uniqueDays = siteEntries.map((e) {
                  return '${e.timestamp.year}-${e.timestamp.month}-${e.timestamp.day}';
                }).toSet();
                final int siteDaysWorked = uniqueDays.length;
                final bool isActive = state.activeSite?.id == site.id;

                return GestureDetector(
                  onTap: () {
                    state.setActiveSite(site);
                    Navigator.pop(context); // Go back to dashboard, which updates automatically
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive 
                            ? const Color(0xFF00F2FE).withValues(alpha: 0.5) 
                            : Colors.white.withValues(alpha: 0.04),
                        width: isActive ? 1.5 : 1.0,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                site.name,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F2FE).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'యాక్టివ్',
                                  style: TextStyle(color: Color(0xFF00F2FE), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'సృష్టించబడిన తేదీ: ${_formatTeluguDate(site.createdAt)}',
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        
                        // Metrics row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'అందిన బడ్జెట్',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatter.format(siteReceived),
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'పని చేసిన రోజులు',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$siteDaysWorked రోజులు',
                                  style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'చేతి నిల్వ',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatter.format(siteCashOnHand),
                                  style: TextStyle(
                                    color: siteCashOnHand >= 0 ? const Color(0xFF10B981) : Colors.red.shade400,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
