import 'package:flutter/material.dart';
import 'package:footbox/database/patient_repository.dart';
import 'package:footbox/models/patient.dart';

class EditProfileSheet extends StatefulWidget {
  final int patientId;
  final ClinicalProfile? existing;

  const EditProfileSheet({
    super.key,
    required this.patientId,
    this.existing,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _repo = PatientRepository();

  Severity _neuropathy = Severity.none;
  Severity _pad = Severity.none;
  DeformityType _deformity = DeformityType.none;
  UlcerSite _priorUlcer = UlcerSite.none;
  bool _amputation = false;
  bool _esrd = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _neuropathy = e.neuropathy;
      _pad = e.pad;
      _deformity = e.deformity;
      _priorUlcer = e.priorUlcerSite;
      _amputation = e.priorAmputation;
      _esrd = e.esrd;
    }
  }

  // Derived preview — mirrors ClinicalProfile.iwgdfRisk getter
  int get _previewRisk {
    if (_amputation ||
        _esrd ||
        _priorUlcer != UlcerSite.none ||
        _pad == Severity.severe ||
        _neuropathy == Severity.severe) {
      return 3;
    }
    if (_neuropathy.index >= 1 &&
        (_pad.index >= 1 || _deformity != DeformityType.none)) {
      return 2;
    }
    if (_neuropathy.index >= 1 ||
        _pad.index >= 1 ||
        _deformity != DeformityType.none) {
      return 1;
    }
    return 0;
  }

  double get _previewThreshold {
    switch (_previewRisk) {
      case 1: return 2.0;
      case 2: return 1.8;
      case 3: return 1.5;
      default: return 2.2;
    }
  }

  Color _riskColor(int risk) {
    switch (risk) {
      case 0: return Colors.green;
      case 1: return Colors.orange;
      case 2: return Colors.deepOrange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _riskLabel(int risk) {
    switch (risk) {
      case 0: return 'Low Risk';
      case 1: return 'Moderate Risk';
      case 2: return 'High Risk';
      case 3: return 'Very High Risk';
      default: return '';
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now().toIso8601String();
    final profile = ClinicalProfile(
      patientId: widget.patientId,
      neuropathy: _neuropathy,
      pad: _pad,
      deformity: _deformity,
      priorUlcerSite: _priorUlcer,
      priorAmputation: _amputation,
      esrd: _esrd,
      updatedAt: now,
    );
    if (widget.existing == null) {
      await _repo.insertProfile(profile);
    } else {
      await _repo.upsertProfile(profile);
    }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ───────────────────────────────────────────────
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null
                  ? 'Add Clinical Profile'
                  : 'Edit Clinical Profile',
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'These factors determine IWGDF risk and ΔT alert thresholds.',
              style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  color: Colors.black45),
            ),

            const SizedBox(height: 20),

            // ── Neuropathy ───────────────────────────────────────────
            _sectionLabel(
              'Peripheral Neuropathy',
              '(nerve damage severity)',
            ),
            const SizedBox(height: 8),
            // Neuropathy
            _segmentedRow(
              options: Severity.values.map((s) => s.label).toList(),
              selected: _neuropathy.index,
              onTap: (i) => setState(() => _neuropathy = Severity.values[i]),
            ),

            const SizedBox(height: 16),

            _sectionLabel(
              'Peripheral Artery Disease (PAD)',
              '(blood flow impairment)',
            ),
            const SizedBox(height: 8),
            _segmentedRow(
              options: Severity.values.map((s) => s.label).toList(),
              selected: _pad.index,
              onTap: (i) => setState(() => _pad = Severity.values[i]),
            ),

            const SizedBox(height: 16),

            // ── Deformity ────────────────────────────────────────────
            _sectionLabel(
              'Foot Deformity',
              '(structural abnormality)',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DeformityType.values.map((d) {
                final selected = _deformity == d;
                return ChoiceChip(
                  label: Text(d.label,
                      style: TextStyle(
                          fontFamily: 'Lexend',
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 13)),
                  selected: selected,
                  selectedColor: Colors.green,
                  onSelected: (_) => setState(() => _deformity = d),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Prior ulcer ──────────────────────────────────────────
            _sectionLabel(
              'Prior Ulcer Site',
              '(previous diabetic foot ulcer location)',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UlcerSite.values.map((s) {
                final selected = _priorUlcer == s;
                return ChoiceChip(
                  label: Text(s.label,
                      style: TextStyle(
                          fontFamily: 'Lexend',
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 13)),
                  selected: selected,
                  selectedColor: Colors.green,
                  onSelected: (_) => setState(() => _priorUlcer = s),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Toggles ──────────────────────────────────────────────
            _sectionLabel('Additional Risk Factors', ''),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _amputation,
                    onChanged: (v) => setState(() => _amputation = v),
                    activeThumbColor: Colors.green,
                    title: const Text('Prior Amputation',
                        style: TextStyle(
                            fontFamily: 'Lexend', fontSize: 14)),
                    subtitle: const Text('Any lower-limb amputation history',
                        style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 12,
                            color: Colors.black45)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _esrd,
                    onChanged: (v) => setState(() => _esrd = v),
                    activeThumbColor: Colors.green,
                    title: const Text('ESRD / Dialysis',
                        style: TextStyle(
                            fontFamily: 'Lexend', fontSize: 14)),
                    subtitle: const Text(
                        'End-stage renal disease or on dialysis',
                        style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 12,
                            color: Colors.black45)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Live risk preview ────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _riskColor(_previewRisk).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _riskColor(_previewRisk).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: _riskColor(_previewRisk), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IWGDF Risk $_previewRisk  ·  ${_riskLabel(_previewRisk)}',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _riskColor(_previewRisk),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ΔT alert threshold: ${(_previewThreshold * 9/5).toStringAsFixed(1)}°F',
                          style: const TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 12,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Save button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.existing == null
                            ? 'Save Profile'
                            : 'Update Profile',
                        style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.bold)),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, String subtitle) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Lexend', color: Colors.black87),
        children: [
          TextSpan(
              text: title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          if (subtitle.isNotEmpty)
            TextSpan(
                text: '  $subtitle',
                style: const TextStyle(
                    fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _segmentedRow({
    required List<String> options,
    required int selected,
    required void Function(int) onTap,
  }) {
    return Row(
      children: List.generate(options.length, (i) {
        final isSelected = selected == i;
        final isFirst = i == 0;
        final isLast = i == options.length - 1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey.shade100,
                border: Border.all(
                    color: isSelected
                        ? Colors.green
                        : Colors.grey.shade300),
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? const Radius.circular(8) : Radius.zero,
                  right: isLast ? const Radius.circular(8) : Radius.zero,
                ),
              ),
              child: Center(
                child: Text(
                  options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}