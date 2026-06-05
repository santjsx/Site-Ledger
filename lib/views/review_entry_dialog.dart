import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../speech_handler.dart';

class ReviewEntryDialog extends StatefulWidget {
  final String siteId;
  final String voiceTranscript;
  final ParsedEntry parsedEntry;
  final DateTime initialDate;

  const ReviewEntryDialog({
    super.key,
    required this.siteId,
    required this.voiceTranscript,
    required this.parsedEntry,
    required this.initialDate,
  });

  @override
  State<ReviewEntryDialog> createState() => _ReviewEntryDialogState();
}

class _ReviewEntryDialogState extends State<ReviewEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _labourCountController;
  late TextEditingController _labourPaidController;
  late TextEditingController _ownerAmountController;
  late TextEditingController _noteController;
  late DateTime _entryDate;

  @override
  void initState() {
    super.initState();
    _entryDate = widget.initialDate;
    
    // Initialize controller values with parsed values if present
    _labourCountController = TextEditingController(
      text: widget.parsedEntry.labourCount?.toString() ?? '',
    );
    _labourPaidController = TextEditingController(
      text: widget.parsedEntry.labourPaid?.toString() ?? '',
    );
    _ownerAmountController = TextEditingController(
      text: widget.parsedEntry.ownerAmount?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: widget.parsedEntry.note ?? '',
    );
  }

  @override
  void dispose() {
    _labourCountController.dispose();
    _labourPaidController.dispose();
    _ownerAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final state = Provider.of<AppState>(context, listen: false);
      
      final int? labourCount = int.tryParse(_labourCountController.text);
      final double? labourPaid = double.tryParse(_labourPaidController.text);
      final double? ownerAmount = double.tryParse(_ownerAmountController.text);
      final String note = _noteController.text.trim();

      final newEntry = LedgerEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        siteId: widget.siteId,
        timestamp: _entryDate,
        voiceTranscript: widget.voiceTranscript,
        labourCount: labourCount,
        labourPaid: labourPaid,
        ownerAmount: ownerAmount,
        note: note.isNotEmpty ? note : null,
      );

      state.addEntry(newEntry);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE)),
              SizedBox(width: 8),
              Text('సేవ్ చేసాము!'),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1329),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white10),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.rate_review_outlined, color: Color(0xFF00F2FE)),
              SizedBox(width: 8),
              Text(
                'వివరాలు ఒకసారి చూసుకోండి',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'కింద ఉన్న వివరాలు కరెక్టో కాదో చూసుకోండి',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spoken Transcript Preview
                Text(
                  'మీరు చెప్పిన మాటలు',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                  ),
                  child: Text(
                    '"${widget.voiceTranscript}"',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Picker Field
                _buildDatePickerField(context),
                const SizedBox(height: 16),

                // Form Fields
                _buildFormField(
                  controller: _labourCountController,
                  label: 'మనుషుల సంఖ్య (కూలీలు)',
                  hint: 'ఎంత మంది కూలీలో రాయండి',
                  icon: Icons.people_rounded,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                      return 'సరైన నెంబర్ రాయండి';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _labourPaidController,
                  label: 'కూలీల ఖర్చు / జీతాలు',
                  hint: 'కూలీలకు ఎంత ఇచ్చారో రాయండి',
                  icon: Icons.payments_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '₹ ',
                  validator: (val) {
                    if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                      return 'సరైన అమౌంట్ రాయండి';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                 _buildFormField(
                  controller: _ownerAmountController,
                  label: 'ఓనర్ ఇచ్చిన పైసలు',
                  hint: 'ఓనర్ మీకు ఇచ్చిన నగదు / అడ్వాన్స్ రాయండి',
                  icon: Icons.download_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '₹ ',
                  validator: (val) {
                    if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                      return 'సరైన అమౌంట్ రాయండి';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _noteController,
                  label: 'సైట్ వివరాలు / నోట్స్',
                  hint: 'మెటీరియల్ లేదా ఇతర వివరాలు ఏవైనా ఉంటే రాయండి',
                  icon: Icons.description_rounded,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          child: Text('వద్దు', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F2FE),
            foregroundColor: const Color(0xFF020617),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _saveEntry,
          child: const Text('సేవ్ చేయి', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF00F2FE).withValues(alpha: 0.7), size: 20),
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.white, fontSize: 14),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade500),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade500, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildDatePickerField(BuildContext context) {
    // Import intl if not imported, but wait, intl is imported?
    // Let's check review_entry_dialog imports.
    // It doesn't import intl. Let's make sure we format the date manually or import intl!
    // Since intl is already in pubspec.yaml, let's use:
    // '${_entryDate.day.toString().padLeft(2, '0')} ${_getMonthName(_entryDate.month)} ${_entryDate.year}'
    // to avoid import issues, or we can just import package:intl/intl.dart!
    // Let's import intl in this chunk or at the top. Let's do it manually:
    final dayStr = _entryDate.day.toString().padLeft(2, '0');
    final months = ['జనవరి', 'ఫిబ్రవరి', 'మార్చి', 'ఏప్రిల్', 'మే', 'జూన్', 'జూలై', 'ఆగస్టు', 'సెప్టెంబరు', 'అక్టోబరు', 'నవంబరు', 'డిసెంబరు'];
    final monthStr = months[_entryDate.month - 1];
    final dateStr = '$dayStr $monthStr ${_entryDate.year}';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _entryDate,
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
          setState(() {
            _entryDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: const Color(0xFF00F2FE).withValues(alpha: 0.7), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'తేదీ (Date)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
