import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _useAiParsing;
  final List<TextEditingController> _apiKeyControllers = [];
  final List<bool> _obscureKeys = [];
  late String _selectedModel;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    _useAiParsing = state.useAiParsing;
    _selectedModel = state.groqModel;

    final keys = state.groqApiKeys;
    if (keys.isEmpty) {
      _apiKeyControllers.add(TextEditingController());
      _obscureKeys.add(true);
    } else {
      for (var k in keys) {
        _apiKeyControllers.add(TextEditingController(text: k));
        _obscureKeys.add(true);
      }
    }
  }

  @override
  void dispose() {
    for (var c in _apiKeyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveSettings() {
    final state = Provider.of<AppState>(context, listen: false);
    final keys = _apiKeyControllers
        .map((c) => c.text.trim())
        .where((k) => k.isNotEmpty)
        .toList();
    
    state.updateAiSettings(
      useAiParsing: _useAiParsing,
      groqApiKeys: keys,
      groqModel: _selectedModel,
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE)),
            SizedBox(width: 8),
            Text('అమరికలు సేవ్ చేయబడ్డాయి! (Settings Saved!)'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1329),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white10),
      ),
      title: Row(
        children: const [
          Icon(Icons.psychology_rounded, color: Color(0xFF00F2FE), size: 28),
          SizedBox(width: 12),
          Text(
            'AI సెట్టింగ్స్ (AI Settings)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle AI parsing
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'AI ఆటో-ఫిల్ ఉపయోగించు',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'వాయిస్ లెడ్జర్ వివరాలను AI తో నింపండి',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                value: _useAiParsing,
                activeColor: const Color(0xFF00F2FE),
                activeTrackColor: const Color(0xFF00F2FE).withValues(alpha: 0.2),
                inactiveThumbColor: const Color(0xFF64748B),
                inactiveTrackColor: Colors.white10,
                onChanged: (bool value) {
                  setState(() {
                    _useAiParsing = value;
                  });
                },
              ),
              const Divider(color: Colors.white10, height: 24),

              // API Keys text fields
              const Text(
                'Groq API Keys',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Column(
                children: List.generate(_apiKeyControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiKeyControllers[index],
                            obscureText: _obscureKeys[index],
                            enabled: _useAiParsing,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'gsk_... (Key #${index + 1})',
                              hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                              prefixIcon: Icon(
                                Icons.vpn_key_rounded,
                                color: (_useAiParsing ? const Color(0xFF00F2FE) : const Color(0xFF475569)).withValues(alpha: 0.7),
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureKeys[index] ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureKeys[index] = !_obscureKeys[index];
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.02)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00F2FE), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ),
                        if (_apiKeyControllers.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                            onPressed: _useAiParsing
                                ? () {
                                    setState(() {
                                      _apiKeyControllers[index].dispose();
                                      _apiKeyControllers.removeAt(index);
                                      _obscureKeys.removeAt(index);
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),

              if (_useAiParsing && _apiKeyControllers.length < 10)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add_rounded, color: Color(0xFF00F2FE), size: 18),
                    label: const Text(
                      'మరో కీని జోడించు (+ Add Another Key)',
                      style: TextStyle(color: Color(0xFF00F2FE), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      setState(() {
                        _apiKeyControllers.add(TextEditingController());
                        _obscureKeys.add(true);
                      });
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // Model Selection Dropdown
              const Text(
                'AI మోడల్ (AI Model)',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: const Color(0xFF0F172A),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedModel,
                  disabledHint: Text(
                    _selectedModel,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.settings_suggest_rounded,
                      color: (_useAiParsing ? const Color(0xFF00F2FE) : const Color(0xFF475569)).withValues(alpha: 0.7),
                      size: 20,
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'llama-3.3-70b-versatile',
                      child: Text('Llama 3.3 70B (Recommended)', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'llama-3.1-8b-instant',
                      child: Text('Llama 3.1 8B (Fastest)', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ],
                  onChanged: _useAiParsing
                      ? (val) {
                          if (val != null) {
                            setState(() {
                              _selectedModel = val;
                            });
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Info card/help text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF00F2FE), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'మరింత సమాచారం (Info)',
                          style: TextStyle(color: Color(0xFF00F2FE), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Groq API అనేది చాలా వేగవంతమైనది మరియు ఉచిత కీని అందిస్తుంది. API కీని సృష్టించడానికి కింద ఉన్న లింక్‌ను ఉపయోగించండి:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    const SelectableText(
                      'https://console.groq.com/',
                      style: TextStyle(color: Color(0xFF00F2FE), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'అనేక API కీలను సమర్పించడం ద్వారా కోటా పరిమితి లోపం (Quota limit error) రాకుండా కీలు ఆటో-రొటేట్ చేయబడతాయి.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ఒకవేళ నెట్ లేకున్నా లేదా API తప్పుగా ఉన్నా, యాప్ లోకల్ ప్రాసెసింగ్ ఉపయోగించి వివరాలు నింపుతుంది.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10, height: 1.4, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          child: const Text('వద్దు (Cancel)', style: TextStyle(color: Color(0xFF94A3B8))),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F2FE),
            foregroundColor: const Color(0xFF020617),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _saveSettings,
          child: const Text('సేవ్ (Save)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
