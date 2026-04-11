import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:FootBox/screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:FootBox/bluetooth/bluetooth_manager.dart';

class BluetoothCheckScreen extends StatefulWidget {
  const BluetoothCheckScreen({super.key});

  @override
  State<BluetoothCheckScreen> createState() => _BluetoothCheckScreenState();
}

class _BluetoothCheckScreenState extends State<BluetoothCheckScreen> { 
  final List<BluetoothDevice> devices = [];
  bool scanning = false;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    requestPermissionsAndScan();
  }

  Future<void> requestPermissionsAndScan() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
    
    startScan();
  }

  Future<void> startScan() async {
    devices.clear();
    setState(() => scanning = true);

    try {
      // Get bonded (paired) devices
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      for (var device in bondedDevices) {
        // Filter for your ESP32 device name
        if (device.name != null && device.name!.contains('ESP32_FootBox')) {
          if (!devices.contains(device)) {
            setState(() => devices.add(device));
          }
        }
      }
    } catch (e) {
      print('Scan error: $e');
    }

    setState(() => scanning = false);
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() => scanning = false);

    try {
      // Show connecting dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Connect to the device
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (!connection.isConnected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to connect to device")),
        );
        return;
      }

      setState(() => connectedDevice = device);

      print('✅ Connected to ${device.name}');
      
      // Store in BluetoothManager
      BluetoothManager.device = device;
      BluetoothManager.connection = connection;

      // Optional: Setup listener for incoming data
      BluetoothManager.setupListener((data) {
        print('Received from ESP32: $data');
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('Connection error: $e');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bluetooth Devices',
          style: TextStyle(fontFamily: 'Lexend'),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            scanning
                ? const LinearProgressIndicator()
                : ElevatedButton(
                    onPressed: startScan,
                    child: const Text('Scan Again'),
                  ),
            const SizedBox(height: 20),
            if (devices.isEmpty && !scanning)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'FootBox not found',
                        style: TextStyle(fontFamily: 'Lexend', fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Make sure your ESP32 is:\n• Powered on\n• Paired in Bluetooth settings',
                        style: TextStyle(fontFamily: 'Lexend', fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isConnected = connectedDevice == device;

                    return ListTile(
                      title: Text(
                        device.name ?? 'Unknown Device',
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                      subtitle: Text(
                        device.address,
                        style: const TextStyle(fontFamily: 'Lexend'),
                      ),
                      trailing: ElevatedButton(
                        onPressed: isConnected
                            ? null
                            : () => connectToDevice(device),
                        child: Text(
                          isConnected ? "Connected" : "Connect",
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}