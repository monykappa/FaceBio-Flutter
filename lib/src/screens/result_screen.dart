import 'package:flutter/material.dart';
import 'package:facebio_flutter/src/models/scan_mode.dart';
import 'package:facebio_flutter/src/models/scan_result.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.success ? Colors.green : Colors.red;
    final modeLabel = result.mode.label;

    return Scaffold(
      appBar: AppBar(title: Text('$modeLabel Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      result.success
                          ? '$modeLabel success'
                          : '$modeLabel failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('User ID: ${result.userId}'),
                    Text('Liveness: ${result.livenessResult.status}'),
                    Text(
                      'Confidence: ${(result.livenessResult.confidence * 100).toStringAsFixed(2)}%',
                    ),
                    if (result.apiMessage.isNotEmpty)
                      Text('Message: ${result.apiMessage}'),
                    if (result.mode == ScanMode.register &&
                        result.embedding != null)
                      Text('Embedding length: ${result.embedding!.length}'),
                    if (result.mode == ScanMode.register &&
                        result.embedding != null)
                      const Text('Embedding stored locally'),
                    if (result.mode == ScanMode.verify &&
                        result.similarity != null)
                      Text(
                        'Similarity: ${result.similarity!.toStringAsFixed(6)}',
                      ),
                    if (result.mode == ScanMode.verify && result.match != null)
                      Text('Match: ${result.match! ? 'true' : 'false'}'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
