import 'package:flutter/material.dart';
import 'package:footbox/database/patient_repository.dart';
import 'package:footbox/models/patient.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patients',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientDetailScreen()),
          );
          _load();
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('New Patient', style: TextStyle(fontFamily: 'Lexend')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _patients.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No patients yet.',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Lexend'),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap + New Patient to add one.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontFamily: 'Lexend'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final p = _patients[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
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
                        title: Text(
                          p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lexend'),
                        ),
                        subtitle: Text(
                          '${p.sex}  ·  ${_age(p.dob)}',
                          style: const TextStyle(
                              fontFamily: 'Lexend', color: Colors.black54),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.green),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PatientDetailScreen(patient: p)),
                          );
                          _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}