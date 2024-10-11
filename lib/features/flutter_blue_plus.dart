import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FlutterBluePlusExam extends StatefulWidget {
  const FlutterBluePlusExam({super.key});
  @override
  State<StatefulWidget> createState() => _FlutterBluePlusExamState();
}

class _FlutterBluePlusExamState extends State<FlutterBluePlusExam> {
  List<ScanResult> _scanResults = [];
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() {
          _adapterState = state;
          print("Adapter state: $state");
        });
      }
    });
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
          print("results is $results");
        });
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Blue Plus'),
        ),
        body: Center(
          child: Column(
            children: [
              ..._scanResults.map((result) {
                return ListTile(
                  title: Text(result.device.name),
                  subtitle: Text(result.device.id.toString()),
                  trailing: Text(result.rssi.toString()),
                );
              }).toList(),
            ],
          ),
        ));
  }
}
