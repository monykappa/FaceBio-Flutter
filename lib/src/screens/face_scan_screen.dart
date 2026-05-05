import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:facebio_flutter/src/models/face_liveness_result.dart';
import 'package:facebio_flutter/src/models/scan_mode.dart';
import 'package:facebio_flutter/src/models/scan_result.dart';
import 'package:facebio_flutter/src/screens/result_screen.dart';
import 'package:facebio_flutter/src/services/embedding_storage_service.dart';
import 'package:facebio_flutter/src/services/face_api_service.dart';
import 'package:facebio_flutter/src/widgets/face_bio_view.dart';

class FaceScanScreen extends StatefulWidget {
  final ScanMode mode;
  final String userId;

  const FaceScanScreen({super.key, required this.mode, required this.userId});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  static const int _maxFailureAttempts = 3;

  final FaceApiService _faceApiService = FaceApiService();
  final EmbeddingStorageService _embeddingStorageService =
      EmbeddingStorageService();

  String _statusMessage = 'Position your face in the frame';
  bool _isSubmitting = false;
  bool _isCompleted = false;
  bool _isFailureDialogOpen = false;
  bool _isScannerVisible = true;
  int _remainingSeconds = 30;
  int _failureAttempts = 0;
  int _scannerSession = 0;
  bool _countdownStarted = false;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownIfNeeded() {
    if (_countdownStarted) {
      return;
    }

    _countdownStarted = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  void _handleStateChanged(String message) {
    if (_isCompleted || _isSubmitting || _isFailureDialogOpen) {
      return;
    }

    _startCountdownIfNeeded();
    if (_statusMessage == message) {
      return;
    }

    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _goToResult(ScanResult scanResult) async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ResultScreen(result: scanResult)),
    );
  }

  void _resetCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownStarted = false;
    _remainingSeconds = 30;
  }

  Future<void> _restartScanner() async {
    if (!mounted) {
      return;
    }

    _resetCountdown();
    setState(() {
      _isCompleted = false;
      _isSubmitting = false;
      _isScannerVisible = false;
      _statusMessage = 'Position your face in the frame';
    });

    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) {
      return;
    }

    setState(() {
      _scannerSession++;
      _isScannerVisible = true;
    });
  }

  Future<void> _handleLibraryFailure(String message) async {
    if (!mounted || _isFailureDialogOpen) {
      return;
    }

    final attempt = _failureAttempts + 1;
    final reachedLimit = attempt >= _maxFailureAttempts;

    _resetCountdown();
    setState(() {
      _failureAttempts = attempt;
      _isSubmitting = false;
      _isFailureDialogOpen = true;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(reachedLimit ? 'Scan Failed' : 'Try Again'),
          content: Text(
            '${message.isEmpty ? 'Face scan failed.' : message}\n\n'
            'Attempt $attempt of $_maxFailureAttempts.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(reachedLimit ? 'Back' : 'Try Again'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isFailureDialogOpen = false;
    });

    if (reachedLimit) {
      Navigator.of(context).pop();
      return;
    }

    await _restartScanner();
  }

  Future<void> _handleResult(FaceLivenessResult livenessResult) async {
    if (_isCompleted || _isSubmitting || _isFailureDialogOpen) {
      return;
    }

    if (!livenessResult.isLive) {
      await _handleLibraryFailure(
        livenessResult.message.isEmpty
            ? 'Liveness check failed'
            : livenessResult.message,
      );
      return;
    }

    final imagePath = livenessResult.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      await _handleLibraryFailure(
        'Captured image path was not returned from native layer',
      );
      return;
    }

    setState(() {
      _isCompleted = true;
      _isSubmitting = true;
      _isScannerVisible = false;
    });

    try {
      if (widget.mode == ScanMode.register) {
        final response = await _faceApiService.registerFace(
          userId: widget.userId,
          imagePath: imagePath,
        );

        await _embeddingStorageService.saveEmbedding(
          userId: widget.userId,
          embedding: response.data.embedding,
        );

        await _goToResult(
          ScanResult(
            mode: widget.mode,
            userId: widget.userId,
            livenessResult: livenessResult,
            apiSuccess: true,
            apiMessage: response.message,
            embedding: response.data.embedding,
          ),
        );
      } else {
        final response = await _faceApiService.verifyFace(
          userId: widget.userId,
          imagePath: imagePath,
        );

        await _goToResult(
          ScanResult(
            mode: widget.mode,
            userId: widget.userId,
            livenessResult: livenessResult,
            apiSuccess: response.data.match,
            apiMessage: response.message,
            similarity: response.data.similarity,
            match: response.data.match,
          ),
        );
      }
    } on FaceApiException catch (error) {
      await _goToResult(
        ScanResult(
          mode: widget.mode,
          userId: widget.userId,
          livenessResult: livenessResult,
          apiSuccess: false,
          apiMessage: error.toString(),
        ),
      );
    } on FormatException catch (error) {
      await _goToResult(
        ScanResult(
          mode: widget.mode,
          userId: widget.userId,
          livenessResult: livenessResult,
          apiSuccess: false,
          apiMessage: 'Invalid API response: ${error.message}',
        ),
      );
    } on HttpException catch (error) {
      await _goToResult(
        ScanResult(
          mode: widget.mode,
          userId: widget.userId,
          livenessResult: livenessResult,
          apiSuccess: false,
          apiMessage: error.message,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.mode.label} Face')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final previewHeight = constraints.maxHeight * 0.65;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!_isCompleted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                  child: SizedBox(
                    height: previewHeight,
                    child: _isScannerVisible
                        ? FaceBioView(
                            key: ValueKey<int>(_scannerSession),
                            maskColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            onResult: (result) => _handleResult(result),
                            onStateChanged: (_, message) =>
                                _handleStateChanged(message),
                            onError: (code, message) {
                              _handleLibraryFailure(
                                message?.isNotEmpty == true
                                    ? message!
                                    : 'Error [$code] while running face scan',
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              if (!_isCompleted)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_countdownStarted && _remainingSeconds > 0)
                          Text(
                            '${_remainingSeconds}s',
                            style: TextStyle(
                              color: _remainingSeconds <= 10
                                  ? Colors.red
                                  : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_isSubmitting)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
