import 'package:flutter/material.dart';
import 'package:facebio_flutter/src/models/scan_mode.dart';

class UserIdDialog extends StatefulWidget {
  final ScanMode mode;

  const UserIdDialog({super.key, required this.mode});

  static Future<String?> show(BuildContext context, {required ScanMode mode}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserIdDialog(mode: mode),
    );
  }

  @override
  State<UserIdDialog> createState() => _UserIdDialogState();
}

class _UserIdDialogState extends State<UserIdDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'User ID is required');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.mode.label} Face'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'User ID',
          hintText: 'Enter user ID',
          errorText: _errorText,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
