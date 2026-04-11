import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:typed_data';

class BluetoothManager {
  static BluetoothDevice? device;
  static BluetoothConnection? connection;
  static String _dataBuffer = '';
  static Function(String)? _onDataReceived;
  
  // Setup listener for incoming data
  static void setupListener(Function(String) onDataReceived) {
    _onDataReceived = onDataReceived;
    
    if (connection != null) {
      connection!.input!.listen((Uint8List data) {
        String received = String.fromCharCodes(data);
        _dataBuffer += received;
        
        // Check if we have a complete line (ESP32 sends data ending with newline)
        if (_dataBuffer.contains('\n')) {
          String completeData = _dataBuffer.trim();
          print('Complete data received: ${completeData.length} characters');
          
          // Call the callback if set
          if (_onDataReceived != null) {
            _onDataReceived!(completeData);
          }
          
          _dataBuffer = ''; // Clear buffer after processing
        }
      }).onDone(() {
        print('Disconnected by remote request');
      });
    }
  }
  
  // Update the callback function (for changing screens)
  static void updateCallback(Function(String)? callback) {
    _onDataReceived = callback;
  }
  
  // Helper method to send commands
  static Future<bool> sendCommand(String command) async {
    if (connection == null || !connection!.isConnected) {
      print('No active connection');
      return false;
    }
    
    try {
      connection!.output.add(Uint8List.fromList(utf8.encode(command + '\n')));
      await connection!.output.allSent;
      print('Command sent: $command');
      return true;
    } catch (e) {
      print('Error sending command: $e');
      return false;
    }
  }
  
  // Disconnect helper
  static Future<void> disconnect() async {
    if (connection != null) {
      await connection!.close();
      connection = null;
      device = null;
      _dataBuffer = '';
      _onDataReceived = null;
      print('Disconnected');
    }
  }
}