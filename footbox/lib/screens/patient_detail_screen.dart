import 'package:flutter/material.dart';
import 'package:footbox/database/patient_repository.dart';
import 'package:footbox/models/patient.dart';
import 'edit_profile_sheet.dart';
import 'package:footbox/database/database_helper.dart';
import 'package:footbox/models/dfu_result.dart';
import 'package:footbox/services/dfu_analyzer.dart';
import 'package:footbox/widgets/dfu_result_widget.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient? patient;
  const PatientDetailScreen({super.key, this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _repo = PatientRepository();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  String _sex = 'Male';
  Patient? _saved;
  ClinicalProfile? _profile;
  bool _saving = false;
  List<Map<String, dynamic>> _sessions = [];
  int? _expandedSessionId;
  List<List<double>> _expandedMatrix = [];
  Map<String, Map<String, double>> _regionStats = {};
  String _selectedRegion = 'all';
  bool _loadingMatrix = false;
  int _minCol = 0, _maxCol = 25;
  DFUResult? _dfuResult;
  bool _analyzingDFU = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _saved = widget.patient;
      _nameController.text = _saved!.name;
      _dobController.text = _saved!.dob;
      _sex = _saved!.sex;
      _loadProfile();
      _loadSessions();
    }
  }

  Future<void> _loadProfile() async {
    if (_saved == null) return;
    final profile = await _repo.getProfileForPatient(_saved!.id!);
    setState(() => _profile = profile);
  }

  Future<void> _loadSessions() async {
  if (_saved == null) return;
  final sessions = await DatabaseHelper.instance
      .getSessionsForPatient(_saved!.id!);
  setState(() => _sessions = sessions);
  }

  Future<DateTime?> _pickDate() async {
    return showDatePicker(
      context: context,
      initialDate: DateTime(1970),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }
    if (_dobController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Date of birth is required.')));
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now().toIso8601String();

    if (_saved == null) {
      final patient = Patient(
        name: name,
        dob: _dobController.text,
        sex: _sex,
        createdAt: now,
      );
      final id = await _repo.insertPatient(patient);
      setState(() {
        _saved = patient.copyWith(id: id);
        _saving = false;
      });
    } else {
      final updated = _saved!.copyWith(
        name: name,
        dob: _dobController.text,
        sex: _sex,
      );
      await _repo.updatePatient(updated);
      setState(() {
        _saved = updated;
        _saving = false;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Patient saved.')));
    }
  }

    String _formatTime(String isoString) {
    final time = DateTime.parse(isoString);
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${time.month}/${time.day}/${time.year}  $hour:$minute $period';
  }

  Future<void> _toggleSession(Map<String, dynamic> session) async {
    final id = session['id'] as int;
    if (_expandedSessionId == id) {
      setState(() {
        _expandedSessionId = null;
        _expandedMatrix = [];
        _regionStats = {};
        _selectedRegion = 'all';
        _dfuResult = null;
        _analyzingDFU = false;
      });
      return;
    }

    setState(() => _loadingMatrix = true);

    final matrix = await DatabaseHelper.instance.getMatrix(id);
    final stats = await DatabaseHelper.instance.getAllRegionStats(id);

    int minCol = 26, maxCol = 0;
    bool hasActive = false;
    for (int r = 0; r < matrix.length; r++) {
      for (int c = 0; c < matrix[r].length; c++) {
        if (matrix[r][c] > 0) {
          if (c < minCol) minCol = c;
          if (c > maxCol) maxCol = c;
          hasActive = true;
        }
      }
    }

    setState(() {
      _expandedSessionId = id;
      _expandedMatrix = matrix;
      _regionStats = stats;
      _selectedRegion = 'all';
      _loadingMatrix = false;
      _minCol = hasActive ? minCol : 0;
      _maxCol = hasActive ? maxCol : 25;
      _analyzingDFU = true;
    });

    final profile = await PatientRepository().getEffectiveProfile(id);
    final result = await DFUAnalyzer.analyze(
        id, session['foot'] as String, profile: profile);
    setState(() {
      _dfuResult = result;
      _analyzingDFU = false;
    });
  }

  Color _regionColor(String region) {
    switch (region) {
      case 'heel': return Colors.purple;
      case 'forefoot': return Colors.blue;
      case 'midfoot': return Colors.orange;
      case 'toes': return Colors.pink;
      default: return Colors.green;
    }
  }

  Color _getHeatmapColor(double value, double min, double max,
      {bool dimmed = false}) {
    double normalized =
        (max - min) > 0 ? (value - min) / (max - min) : 0.0;
    Color base;
    if (normalized < 0.25) {
      base = Color.lerp(Colors.blue, Colors.cyan, normalized * 4)!;
    } else if (normalized < 0.5) {
      base = Color.lerp(
          Colors.cyan, Colors.green, (normalized - 0.25) * 4)!;
    } else if (normalized < 0.75) {
      base = Color.lerp(
          Colors.green, Colors.yellow, (normalized - 0.5) * 4)!;
    } else {
      base = Color.lerp(
          Colors.yellow, Colors.red, (normalized - 0.75) * 4)!;
    }
    return dimmed ? base.withValues(alpha: 0.2) : base;
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete patient?',
            style: TextStyle(fontFamily: 'Lexend')),
        content: const Text(
            'This will remove the patient and their clinical profile. Scans are kept.',
            style: TextStyle(fontFamily: 'Lexend')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && _saved != null) {
      await _repo.deletePatient(_saved!.id!);
      if (mounted) Navigator.pop(context);
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
      default: return 'Unknown';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _saved == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? 'New Patient' : _saved!.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Basic info card ──────────────────────────────────────
            const Text('Patient Info',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Lexend',
                    color: Colors.black54)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(fontFamily: 'Lexend'),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'Lexend'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () async {
                        final d = await _pickDate();
                        if (d != null) {
                          setState(() =>
                              _dobController.text = _formatDate(d));
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        labelStyle: TextStyle(fontFamily: 'Lexend'),
                        border: OutlineInputBorder(),
                        suffixIcon:
                            Icon(Icons.calendar_today, size: 18),
                      ),
                      style: const TextStyle(fontFamily: 'Lexend'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: const InputDecoration(
                        labelText: 'Sex',
                        labelStyle: TextStyle(fontFamily: 'Lexend'),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(
                          fontFamily: 'Lexend', color: Colors.black),
                      items: ['Male', 'Female', 'Other']
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: const TextStyle(
                                      fontFamily: 'Lexend'))))
                          .toList(),
                      onChanged: (v) => setState(() => _sex = v!),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
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
                        isNew ? 'Save Patient' : 'Update Patient',
                        style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.bold)),
              ),
            ),

            // ── Clinical profile (only after patient saved) ──────────
            if (!isNew) ...[
              const SizedBox(height: 28),
              const Text('Clinical Profile',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Lexend',
                      color: Colors.black54)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _profile == null
                      ? Column(
                          children: [
                            const Text(
                              'No clinical profile yet. Add one to enable risk-adapted thresholds.',
                              style: TextStyle(
                                  fontFamily: 'Lexend',
                                  color: Colors.black54,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                    ),
                                    builder: (_) => EditProfileSheet(
                                        patientId: _saved!.id!),
                                  );
                                  _loadProfile();
                                },
                                icon: const Icon(Icons.add,
                                    color: Colors.green),
                                label: const Text('Add Clinical Profile',
                                    style: TextStyle(
                                        fontFamily: 'Lexend',
                                        color: Colors.green)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.green),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // IWGDF risk badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _riskColor(_profile!.iwgdfRisk)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _riskColor(
                                        _profile!.iwgdfRisk)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_outlined,
                                      size: 16,
                                      color: _riskColor(
                                          _profile!.iwgdfRisk)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'IWGDF Risk ${_profile!.iwgdfRisk}  ·  ${_riskLabel(_profile!.iwgdfRisk)}',
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _riskColor(
                                          _profile!.iwgdfRisk),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _profileRow('ΔT Threshold',
                                '${(_profile!.deltaThreshold * 9/5).toStringAsFixed(1)}°F'),
                            _profileRow('Neuropathy',
                                _profile!.neuropathy.label),
                            _profileRow('PAD', _profile!.pad.label),
                            _profileRow('Deformity',
                                _profile!.deformity.label),
                            _profileRow('Prior Ulcer',
                                _profile!.priorUlcerSite.label),
                            _profileRow('Amputation',
                                _profile!.priorAmputation ? 'Yes' : 'No'),
                            _profileRow(
                                'ESRD', _profile!.esrd ? 'Yes' : 'No'),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                    ),
                                    builder: (_) => EditProfileSheet(
                                      patientId: _saved!.id!,
                                      existing: _profile,
                                    ),
                                  );
                                  _loadProfile();
                                },
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.green),
                                label: const Text('Edit Profile',
                                    style: TextStyle(
                                        fontFamily: 'Lexend',
                                        color: Colors.green)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.green),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
            // ── Past Scans (only after patient saved) ────────────────
if (!isNew) ...[
  const SizedBox(height: 28),
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text('Past Scans',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Lexend',
              color: Colors.black54)),
      Text('${_sessions.length} scan${_sessions.length == 1 ? '' : 's'}',
          style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 12,
              color: Colors.black38)),
    ],
  ),
  const SizedBox(height: 8),
  if (_sessions.isEmpty)
    const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No scans linked to this patient yet.',
          style: TextStyle(
              fontFamily: 'Lexend',
              color: Colors.black45,
              fontSize: 13),
        ),
      ),
    )
  else
    ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final id = session['id'] as int;
        final isExpanded = _expandedSessionId == id;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text('$id',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lexend')),
                ),
                title: Text(
                  'Session $id — ${session['foot']} Foot',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend'),
                ),
                subtitle: Text(
                  _formatTime(session['timestamp']),
                  style: const TextStyle(fontFamily: 'Lexend'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () async {
                        await DatabaseHelper.instance
                            .deleteSession(id);
                        if (_expandedSessionId == id) {
                          setState(() {
                            _expandedSessionId = null;
                            _expandedMatrix = [];
                            _regionStats = {};
                          });
                        }
                        _loadSessions();
                      },
                    ),
                    Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.green,
                    ),
                  ],
                ),
                onTap: () => _toggleSession(session),
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                _loadingMatrix
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            color: Colors.green),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Filter by Region',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Lexend')),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  'all',
                                  'toes',
                                  'forefoot',
                                  'midfoot',
                                  'heel'
                                ].map((region) {
                                  final isSelected =
                                      _selectedRegion == region;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        right: 8),
                                    child: ChoiceChip(
                                      label: Text(
                                        region[0].toUpperCase() +
                                            region.substring(1),
                                        style: const TextStyle(
                                            fontFamily: 'Lexend'),
                                      ),
                                      selected: isSelected,
                                      selectedColor: region == 'all'
                                          ? Colors.green
                                          : _regionColor(region),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontFamily: 'Lexend',
                                      ),
                                      onSelected: (_) => setState(
                                          () => _selectedRegion =
                                              region),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_selectedRegion != 'all' &&
                                _regionStats.containsKey(
                                    _selectedRegion)) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _regionColor(_selectedRegion)
                                      .withValues(alpha: .1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _regionColor(
                                              _selectedRegion)
                                          .withValues(alpha: .4)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _statBox(
                                        'AVG',
                                        '${_regionStats[_selectedRegion]!['avg']!.toStringAsFixed(1)}°F',
                                        _regionColor(_selectedRegion)),
                                    _statBox(
                                        'MAX',
                                        '${_regionStats[_selectedRegion]!['max']!.toStringAsFixed(1)}°F',
                                        _regionColor(_selectedRegion)),
                                    _statBox(
                                        'MIN',
                                        '${_regionStats[_selectedRegion]!['min']!.toStringAsFixed(1)}°F',
                                        _regionColor(_selectedRegion)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Builder(builder: (context) {
                              double minVal = double.infinity;
                              double maxVal =
                                  double.negativeInfinity;
                              for (var row in _expandedMatrix) {
                                for (var v in row) {
                                  if (v > 0) {
                                    if (v < minVal) minVal = v;
                                    if (v > maxVal) maxVal = v;
                                  }
                                }
                              }
                              if (minVal == maxVal) {
                                minVal -= 1;
                                maxVal += 1;
                              }
                              return AspectRatio(
                                aspectRatio: 26 / 12,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: CustomPaint(
                                    painter: _PatientScanHeatmapPainter(
                                      matrix: _expandedMatrix,
                                      minValue: minVal,
                                      maxValue: maxVal,
                                      selectedRegion: _selectedRegion,
                                      minCol: _minCol,
                                      maxCol: _maxCol,
                                      getColor: _getHeatmapColor,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            const Text('DFU Risk Analysis',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Lexend')),
                            const SizedBox(height: 8),
                            if (_analyzingDFU)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                      color: Colors.red),
                                ),
                              )
                            else if (_dfuResult != null)
                              DFUResultWidget(
                                result: _dfuResult!,
                                currentFoot:
                                    session['foot'] as String,
                              )
                            else
                              const Text(
                                'No opposite foot scan available for comparison.',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Lexend',
                                    color: Colors.black45),
                              ),
                          ],
                        ),
                      ),
              ],
            ],
          ),
        );
      },
    ),
],
            ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 13,
                  color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _statBox(String label, String value, Color color) {
  return Column(
    children: [
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend')),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend')),
    ],
  );
}
}
class _PatientScanHeatmapPainter extends CustomPainter {
  final List<List<double>> matrix;
  final double minValue;
  final double maxValue;
  final String selectedRegion;
  final int minCol;
  final int maxCol;
  final Color Function(double, double, double, {bool dimmed}) getColor;

  _PatientScanHeatmapPainter({
    required this.matrix,
    required this.minValue,
    required this.maxValue,
    required this.selectedRegion,
    required this.minCol,
    required this.maxCol,
    required this.getColor,
  });

  bool _inRegion(int col) {
    if (selectedRegion == 'all') return true;
    final int range = (maxCol - minCol).clamp(1, 26);
    final double norm = (col - minCol) / range;
    switch (selectedRegion) {
      case 'toes': return norm < 0.15;
      case 'forefoot': return norm >= 0.15 && norm < 0.40;
      case 'midfoot': return norm >= 0.40 && norm < 0.70;
      case 'heel': return norm >= 0.70;
      default: return true;
    }
  }

  double _interpolate(double x, double y) {
    int x0 = x.floor().clamp(0, matrix[0].length - 1);
    int y0 = y.floor().clamp(0, matrix.length - 1);
    int x1 = (x0 + 1).clamp(0, matrix[0].length - 1);
    int y1 = (y0 + 1).clamp(0, matrix.length - 1);
    double fx = x - x0, fy = y - y0;
    double v00 = matrix[y0][x0], v10 = matrix[y0][x1];
    double v01 = matrix[y1][x0], v11 = matrix[y1][x1];
    double v0 = v00 * (1 - fx) + v10 * fx;
    double v1 = v01 * (1 - fx) + v11 * fx;
    return v0 * (1 - fy) + v1 * fy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const int upscaleFactor = 4;
    final int cols = matrix[0].length;
    final int rows = matrix.length;
    final int width = cols * upscaleFactor;
    final int height = rows * upscaleFactor;
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    for (int px = 0; px < width; px++) {
      for (int py = 0; py < height; py++) {
        double mx = px / upscaleFactor;
        double my = py / upscaleFactor;
        double value = _interpolate(mx, my);
        int col = mx.floor().clamp(0, cols - 1);
        bool inRegion = _inRegion(col);
        Color color =
            getColor(value, minValue, maxValue, dimmed: !inRegion);
        final paint = Paint()..color = color;
        canvas.drawRect(
          Rect.fromLTWH(px * pixelWidth, py * pixelHeight,
              pixelWidth + 0.5, pixelHeight + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}