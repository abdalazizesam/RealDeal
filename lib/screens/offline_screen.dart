import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const OfflineScreen({Key? key, required this.onRetry}) : super(key: key);

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // backgroundColor will be inherited from the global theme
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 80,
                // color: Colors.red[400], // Use themed color
                color: colorScheme.error, // Or colorScheme.onSurfaceVariant for a less strong color
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: textTheme.headlineSmall?.copyWith( // M3 typography
                  // color: colorScheme.onBackground, // Will inherit if not specified
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12), // Adjusted spacing
              Text(
                'Please check your internet connection and try again to explore movies and TV shows.',
                style: textTheme.bodyMedium?.copyWith( // M3 typography
                  // color: colorScheme.onSurfaceVariant, // Will inherit or use a slightly muted color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, // Make button take available width
                child: FilledButton.icon( // Using FilledButton for primary action
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  onPressed: widget.onRetry,
                  style: FilledButton.styleFrom(
                    // backgroundColor: Colors.red, // Will use colorScheme.primary by default
                    // foregroundColor: colorScheme.onPrimary, // Default for FilledButton
                    padding: const EdgeInsets.symmetric(vertical: 14), // Adjusted padding
                    textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), // M3 button text style
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // M3 standard radius
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Connectivity helper remains the same
class ConnectivityHelper {
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Stream<ConnectivityResult> get connectivityStream =>
      Connectivity().onConnectivityChanged;
}