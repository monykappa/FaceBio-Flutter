import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'face_bio_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceBio Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _startScan(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!context.mounted) return;
    if (status.isGranted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceScanPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FaceBio Demo')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _startScan(context),
          icon: const Icon(Icons.face),
          label: const Text('Start Face Scan'),
        ),
      ),
    );
  }
}

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});
  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  String _statusMessage = 'Position your face in the frame';
  bool _done = false;
  int _remainingSeconds = 30;
  Timer? _countdownTimer;
  bool _countdownStarted = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownIfNeeded() {
    if (_countdownStarted) return;
    _countdownStarted = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) timer.cancel();
      });
    });
  }

  void _onResult(FaceLivenessResult result) {
    setState(() => _done = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(result.isLive ? '✅ Liveness Passed' : '❌ Liveness Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prediction : ${result.prediction}'),
            Text('Confidence : ${(result.confidence * 100).toStringAsFixed(1)}%'),
            Text('Status     : ${result.status}'),
            if (result.message.isNotEmpty) Text('Message    : ${result.message}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Scan')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final previewHeight = constraints.maxHeight * 0.65;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_done)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                  child: SizedBox(
                    height: previewHeight,
                    child: FaceBioView(
                      maskColor: Theme.of(context).scaffoldBackgroundColor,
                      onResult: _onResult,
                      onStateChanged: (state, message) {
                        _startCountdownIfNeeded();
                        setState(() => _statusMessage = message);
                      },
                      onError: (code, message) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error [$code]: $message')),
                        );
                      },
                    ),
                  ),
                ),
              if (!_done)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        if (_countdownStarted && _remainingSeconds > 0)
                          Text(
                            '${_remainingSeconds}s',
                            style: TextStyle(
                              color: _remainingSeconds <= 10 ? Colors.red : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
