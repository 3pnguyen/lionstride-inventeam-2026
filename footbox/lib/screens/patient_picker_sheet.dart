import 'package:flutter/material.dart';
import 'package:footbox/database/patient_repository.dart';
import 'package:footbox/models/patient.dart';

class PatientPickerSheet extends StatefulWidget {
  const PatientPickerSheet({super.key});

  @override
  State<PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<PatientPickerSheet> {
  final _repo = PatientRepository();
  List<Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patients = await _repo.getAllPatients();
    setState(() {
      _patients = patients;
      _loading = false;
    });
  }

  String _age(String dob) {
    try {
      final parts = dob.split('/');
      final d = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
      final today = DateTime.now();
      int age = today.year - d.year;
      if (today.month < d.month ||
          (today.month == d.month && today.day < d.day)) {
        age--;
      }
      return '$age y/o';
    } catch (_) {
      return dob;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          const Text(
            'Link to Patient',
            style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a patient to link this scan, or skip to save without linking.',
            style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 12,
                color: Colors.black45),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: Colors.green))
          else if (_patients.isEmpty)
            const Text(
              'No patients found. Add one from the Patients screen first.',
              style: TextStyle(
                  fontFamily: 'Lexend',
                  color: Colors.black45,
                  fontSize: 13),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final p = _patients[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lexend'),
                    ),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${p.sex}  ·  ${_age(p.dob)}',
                    style: const TextStyle(
                        fontFamily: 'Lexend', color: Colors.black54),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.green),
                  onTap: () => Navigator.pop(context, p.id),
                );
              },
            ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Skip button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // CHANGED HERE: Return -1 instead of null to indicate "Skip"
              onPressed: () => Navigator.pop(context, -1),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Skip — don\'t link to a patient',
                style: TextStyle(
                    fontFamily: 'Lexend',
                    color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}