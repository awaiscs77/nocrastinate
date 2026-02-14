import 'package:flutter/material.dart';



class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nocrastinate - Error',
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to Initialize App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // You could implement app restart logic here
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SafeDialogHelper {
  // Safe way to show dialogs that won't cause lifecycle errors
  static Future<T?> showSafeDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return null;

    return await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  // Safe way to pop dialogs
  static void safePop<T>(BuildContext context, [T? result]) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  // Safe way to show delete confirmation dialog
  static Future<bool> showDeleteConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    if (!context.mounted) return false;

    final result = await showSafeDialog<bool>(
      context: context,
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => safePop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              safePop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}