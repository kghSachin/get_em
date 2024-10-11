import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanPage extends StatefulWidget {
  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  Map<String, BluetoothConnectionState> _connectionStates = {};

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {
          print("Adapter state: $_adapterState");
        });
      }
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          print("results is $results");
          _scanResults = results;
          for (var result in results) {
            _connectionStates[result.device.id.id] =
                BluetoothConnectionState.disconnected;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    stopScan();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  void startScan() async {
    if (_isScanning) return;

    if (_adapterState != BluetoothAdapterState.on) {
      print('Bluetooth is not on');
      return;
    }

    await requestPermissions();

    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
    } catch (e) {
      print('Error starting scan: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> connectToDeviceWithCheck(BluetoothDevice device) async {
    try {
      print('Checking state of ${device}');

      // Check if device is already connected
      if (await device.isConnected) {
        print('${device.name} is already connected');
        return;
      }

      print('Attempting to connect to ${device.name}');
      await device.connect(timeout: const Duration(seconds: 10));
      setState(() {
        _connectionStates[device.id.id] = BluetoothConnectionState.connected;
      });
      print('Successfully connected to ${device.name}');
    } catch (e) {
      print('Error connecting to device: $e');
      rethrow;
    }
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();

      setState(() {
        _connectionStates[device.id.id] = BluetoothConnectionState.disconnected;
      });
      print('Disconnected from ${device.name}');
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner and Connector'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isScanning ? stopScan : startScan,
            child: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                final isConnected = _connectionStates[result.device.id.id] ==
                    BluetoothConnectionState.connected;
                return ListTile(
                  title: Text(result.device.name.isNotEmpty
                      ? result.device.name
                      : 'Unknown Device'),
                  subtitle: Text(result.device.id.id),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${result.rssi} dBm'),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (isConnected) {
                            disconnectFromDevice(result.device);
                          } else {
                            print('Connecting to ${result.device.remoteId}');
                            connectToDeviceWithCheck(result.device);
                          }
                        },
                        child: Text(isConnected ? 'Disconnect' : 'Connect'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
