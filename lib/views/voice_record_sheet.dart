import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../groq_service.dart';
import '../speech_handler.dart';
import 'review_entry_dialog.dart';

class VoiceRecordSheet extends StatefulWidget {
  final String siteId;
  final DateTime initialDate;
  const VoiceRecordSheet({super.key, required this.siteId, required this.initialDate});

  @override
  State<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<VoiceRecordSheet> with SingleTickerProviderStateMixin {
  final SpeechHandler _speechHandler = SpeechHandler();
  late AnimationController _waveController;
  
  String _accumulatedTranscript = '';
  String _currentTranscript = '';
  String _statusText = 'మైక్ రెడీ అవుతోంది...';
  bool _isInitializing = true;
  bool _hasPermissions = false;
  String _localeId = 'te-IN';
  bool _userStopped = false;

  String _mergeTranscripts(String s1, String s2) {
    s1 = s1.trim();
    s2 = s2.trim();
    if (s1.isEmpty) return s2;
    if (s2.isEmpty) return s1;

    final words1 = s1.split(RegExp(r'\s+'));
    final words2 = s2.split(RegExp(r'\s+'));

    int maxWordOverlap = 0;
    int minLen = words1.length < words2.length ? words1.length : words2.length;

    for (int i = 1; i <= minLen; i++) {
      bool match = true;
      for (int j = 0; j < i; j++) {
        final w1 = words1[words1.length - i + j].toLowerCase();
        final w2 = words2[j].toLowerCase();
        if (w1 != w2) {
          match = false;
          break;
        }
      }
      if (match) {
        maxWordOverlap = i;
      }
    }

    if (maxWordOverlap > 0) {
      final nonOverlapping = words2.sublist(maxWordOverlap);
      if (nonOverlapping.isEmpty) {
        return s1;
      }
      return '$s1 ${nonOverlapping.join(' ')}';
    }

    // Check character-level overlap
    int maxCharOverlap = 0;
    int minCharLen = s1.length < s2.length ? s1.length : s2.length;
    for (int i = 1; i <= minCharLen; i++) {
      final sub1 = s1.substring(s1.length - i).toLowerCase();
      final sub2 = s2.substring(0, i).toLowerCase();
      if (sub1 == sub2) {
        maxCharOverlap = i;
      }
    }

    if (maxCharOverlap >= 3) {
      return s1 + s2.substring(maxCharOverlap);
    }

    return '$s1 $s2';
  }

  String get _fullTranscript {
    return _mergeTranscripts(_accumulatedTranscript, _currentTranscript);
  }

  @override
  void initState() {
    super.initState();
    
    // Setup animation controller for smooth waveform animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speechHandler.initialize(
      onStatus: (status) {
        if (mounted) {
          setState(() {
            if (status == 'listening') {
              _statusText = 'వింటున్నాను... చెప్పండి';
            } else if (status == 'notListening') {
              _statusText = 'వినడం ఆగింది';
            } else {
              _statusText = status;
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _statusText = 'చిన్న లోపం: $error';
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isInitializing = false;
        _hasPermissions = available;
        if (available) {
          _statusText = 'మాట్లాడటానికి మైక్ నొక్కండి';
          _startRecording(); // Auto-start recording for better UX
        } else {
          _statusText = 'మైక్ పర్మిషన్ లేదు లేదా పని చేయడం లేదు';
        }
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermissions) return;

    setState(() {
      _userStopped = false;
      _currentTranscript = '';
      _statusText = 'వింటున్నాను... చెప్పండి';
    });

    try {
      await _speechHandler.startListening(
        localeId: _localeId,
        onResult: (text) {
          if (mounted) {
            setState(() {
              final newText = text.trim();
              if (newText.isEmpty) return;
              
              final curText = _currentTranscript.trim();
              if (curText.isEmpty) {
                _currentTranscript = newText;
              } else if (newText.toLowerCase().startsWith(curText.toLowerCase())) {
                // Case A: The engine is accumulating words in the current session
                _currentTranscript = newText;
              } else {
                // Case B: The engine returned a new segment/word without accumulation.
                // We commit the previous segment to accumulated transcript with smart overlap merging.
                _accumulatedTranscript = _mergeTranscripts(_accumulatedTranscript, curText);
                _currentTranscript = newText;
              }
            });
          }
        },
        onDone: () {
          _commitCurrentTranscript();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'మైక్ స్టార్ట్ అవ్వలేదు: $e';
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _userStopped = true;
    });
    await _speechHandler.stopListening();
  }

  Future<void> _stopAndProcess() async {
    setState(() {
      _userStopped = true;
      _statusText = 'ఆగుతోంది... విశ్లేషిస్తున్నాము...';
    });
    await _speechHandler.stopListening();
    // Wait briefly for the final transcript segment to be committed
    await Future.delayed(const Duration(milliseconds: 600));
    _processTranscriptAndReview(_fullTranscript);
  }

  void _commitCurrentTranscript() {
    if (mounted) {
      setState(() {
        final cur = _currentTranscript.trim();
        if (cur.isNotEmpty) {
          _accumulatedTranscript = _mergeTranscripts(_accumulatedTranscript, cur);
          _currentTranscript = '';
        }
        
        if (_userStopped) {
          _statusText = _accumulatedTranscript.isEmpty 
              ? 'మాట్లాడటానికి మైక్ నొక్కండి' 
              : 'రికార్డింగ్ ఆగింది. మరికొన్ని వివరాలు చెప్పడానికి మైక్ నొక్కండి.';
        } else {
          // Continuous recording loop: restart automatically after short silence pause
          _statusText = 'వింటున్నాను... చెప్పండి';
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_userStopped) {
              if (!_speechHandler.isListening) {
                _startRecording();
              } else {
                // Double-check retry: if device is slow to close the previous session, try again in 200ms
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted && !_userStopped && !_speechHandler.isListening) {
                    _startRecording();
                  }
                });
              }
            }
          });
        }
      });
    }
  }

  void _processTranscriptAndReview(String finalText) async {
    if (!mounted) return;
    
    final trimmedText = finalText.trim();
    if (trimmedText.isEmpty) {
      setState(() {
        _statusText = 'ముందు ఏవైనా వివరాలు చెప్పండి.';
      });
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    // If AI parsing is enabled and at least one api key is present, let's call the Groq API!
    if (appState.useAiParsing && appState.groqApiKeys.any((key) => key.trim().isNotEmpty)) {
      // 1. Show the loading dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0B1329),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white10),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00F2FE)),
                  const SizedBox(height: 20),
                  const Text(
                    'AI తో వివరాలు విశ్లేషిస్తున్నాము...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Parsing your transcript using Groq AI...',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      );

      try {
        // 2. Parse using GroqService
        final parsed = await GroqService.parseTranscript(
          trimmedText,
          appState.groqApiKeys,
          appState.groqModel,
        );

        // 3. Dismiss loading dialog
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context); // Close voice recording sheet
        }

        // 4. Open the review entry dialog
        if (mounted) {
          _showReviewDialog(trimmedText, parsed);
        }
      } catch (e) {
        // If Groq parsing fails, dismiss loading dialog and fall back to local parser!
        debugPrint('Groq AI Parsing failed: $e');
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context); // Close voice recording sheet
          
          // Show info message about fallback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'AI విశ్లేషణ విఫలమైంది: $e. లోకల్ ఫాల్‌బ్యాక్ ఉపయోగిస్తున్నాము.',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.red.shade900,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Parse with local parser as fallback
          final fallbackParsed = LedgerNlpParser.parse(trimmedText);
          _showReviewDialog(trimmedText, fallbackParsed);
        }
      }
    } else {
      // Direct local parsing
      Navigator.pop(context); // Close voice recording sheet
      final parsed = LedgerNlpParser.parse(trimmedText);
      _showReviewDialog(trimmedText, parsed);
    }
  }

  void _showReviewDialog(String text, ParsedEntry parsed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ReviewEntryDialog(
          siteId: widget.siteId,
          voiceTranscript: parsed.cleanedTranscript ?? text,
          parsedEntry: parsed,
          initialDate: widget.initialDate,
        );
      },
    );
  }

  @override
  void dispose() {
    _speechHandler.cancelListening();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isListening = _speechHandler.isListening;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: MainChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top pull bar
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Speech Language Selector
            _buildLanguageSelector(isListening),
            const SizedBox(height: 24),
            
            // App state / prompt
            Text(
              _statusText,
              style: TextStyle(
                color: isListening ? const Color(0xFF00F2FE) : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Transcript Box
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _fullTranscript.isEmpty
                      ? 'మీరు మాట్లాడేది ఇక్కడ వస్తుంది...'
                      : _fullTranscript,
                  style: TextStyle(
                    color: _fullTranscript.isEmpty ? const Color(0xFF475569) : Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Waveform visualizer
            if (isListening)
              SizedBox(
                height: 60,
                width: double.infinity,
                child: CustomPaint(
                  painter: WaveformPainter(
                    animation: _waveController,
                    color: const Color(0xFF00F2FE),
                  ),
                ),
              )
            else
              const SizedBox(height: 60),

            const SizedBox(height: 24),

            // Dynamic mic toggle & action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clear/Reset Button
                if (!isListening && _accumulatedTranscript.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 28),
                      tooltip: 'మొదటి నుండి చెప్పండి',
                      onPressed: () {
                        setState(() {
                          _accumulatedTranscript = '';
                          _currentTranscript = '';
                          _statusText = 'మాట్లాడటానికి మైక్ నొక్కండి';
                        });
                      },
                    ),
                  )
                else if (!isListening)
                  const SizedBox(width: 44), // Placeholder to keep mic centered

                // Main Recording Button
                if (isListening)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _stopAndProcess,
                    child: const Icon(Icons.stop_rounded, size: 32),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: const Color(0xFF00F2FE),
                      foregroundColor: const Color(0xFF020617),
                      disabledBackgroundColor: const Color(0xFF1E293B),
                    ),
                    onPressed: _isInitializing || !_hasPermissions ? null : _startRecording,
                    child: const Icon(Icons.mic_rounded, size: 32),
                  ),

                // Proceed / Done Button
                if (!isListening && _fullTranscript.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF10B981), // Emerald green for done
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      onPressed: () {
                        _processTranscriptAndReview(_fullTranscript);
                      },
                      child: const Icon(Icons.check_rounded, size: 28),
                    ),
                  )
                else if (!isListening)
                  const SizedBox(width: 44), // Placeholder to keep mic centered
              ],
            ),
            const SizedBox(height: 16),
            
            // Cancel button
            TextButton(
              onPressed: () {
                _speechHandler.cancelListening();
                Navigator.pop(context);
              },
              child: const Text(
                'రద్దు చేయి',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),
            // Footnote warning if Telugu is active
            if (_localeId == 'te-IN')
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  'ఫోన్‌లో తెలుగు పని చేయకపోతే, పైన "English" ఎంచుకోండి.',
                  style: TextStyle(color: Colors.white30, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isListening) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageTab(
            label: 'తెలుగు (Telugu)',
            isSelected: _localeId == 'te-IN',
            onTap: isListening
                ? null
                : () {
                    setState(() {
                      _localeId = 'te-IN';
                    });
                  },
          ),
          _buildLanguageTab(
            label: 'English (ఇంగ్లీష్)',
            isSelected: _localeId == 'en-IN',
            onTap: isListening
                ? null
                : () {
                    setState(() {
                      _localeId = 'en-IN';
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTab({
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: onTap == null && !isSelected ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00F2FE) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF020617) : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Waveform Painter
class WaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WaveformPainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final yCenter = size.height / 2;
    final width = size.width;

    // Draw 3 layers of sine waves with different phases and frequencies
    for (int waveIdx = 0; waveIdx < 3; waveIdx++) {
      final double phaseShift = animation.value * 2 * math.pi + (waveIdx * math.pi / 3);
      final double amplitude = 20.0 - (waveIdx * 5);
      final double frequency = 0.03 + (waveIdx * 0.01);
      
      paint.color = color.withValues(alpha: 0.8 - (waveIdx * 0.25));
      path.reset();
      path.moveTo(0, yCenter);

      for (double x = 0; x < width; x++) {
        // Apply envelope to taper ends of the wave
        final double envelope = math.sin((x / width) * math.pi);
        final double y = yCenter + math.sin(x * frequency + phaseShift) * amplitude * envelope;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Simple Helper to handle scrolling inside Bottom Sheets
class MainChildScrollView extends StatelessWidget {
  final Widget child;
  const MainChildScrollView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    );
  }
}
