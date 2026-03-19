import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class BluetoothPrinterService {
  /// Returns a list of available COM ports on the Windows machine.
  /// (When a Bluetooth printer is paired in Windows, it generates a virtual COM port).
  static List<String> getAvailableComPorts() {
    return SerialPort.availablePorts;
  }

  /// Opens the serial port, streams the bytes, and closes it.
  static Future<bool> printBytes(String comPortName, List<int> bytes) async {
    final port = SerialPort(comPortName);
    
    try {
      if (!port.openWrite()) {
        print("Failed to open port: $comPortName");
        return false;
      }
      
      // ESC/POS printers typically expect 9600 baud rate or higher.
      final config = SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..stopBits = 1
        ..parity = 0;
      port.config = config;

      int bytesWritten = port.write(Uint8List.fromList(bytes));
      
      port.dispose();
      return bytesWritten == bytes.length;
    } catch (e) {
      print("Bluetooth Serial Printing Error: $e");
      if (port.isOpen) port.dispose();
      return false;
    }
  }
}
