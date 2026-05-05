import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:facebio_flutter/src/models/scan_mode.dart';
import 'package:facebio_flutter/src/screens/face_scan_screen.dart';
import 'package:facebio_flutter/src/widgets/user_id_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _startFlow(BuildContext context, ScanMode mode) async {
    final userId = await UserIdDialog.show(context, mode: mode);
    if (!context.mounted || userId == null) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!context.mounted) {
      return;
    }

    final permission = await Permission.camera.request();
    if (!context.mounted) {
      return;
    }

    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FaceScanScreen(mode: mode, userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FaceBio')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FilledButton(
                  onPressed: () => _startFlow(context, ScanMode.register),
                  child: const Text('Register'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _startFlow(context, ScanMode.verify),
                  child: const Text('Verify'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
