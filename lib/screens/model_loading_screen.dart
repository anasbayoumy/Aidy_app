import 'package:flutter/material.dart';
import '../services/model_downloader.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelLoadingScreen extends StatefulWidget {
  const ModelLoadingScreen({super.key});

  @override
  State<ModelLoadingScreen> createState() => _ModelLoadingScreenState();
}

class _ModelLoadingScreenState extends State<ModelLoadingScreen> {
  double _progress = 0.0;
  String _status = 'Checking model...';
  bool _checking = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final modelReady = prefs.getBool('model_ready') ?? false;
    if (modelReady) {
      _goToHome();
    } else {
      _checkAndDownloadModel(prefs);
    }
  }

  Future<void> _checkAndDownloadModel([SharedPreferences? prefs]) async {
    setState(() {
      _checking = true;
      _progress = 0.0;
      _status = 'Checking model...';
    });
    try {
      final complete = await ModelDownloader.modelIsComplete();
      if (complete) {
        await _setModelReady(prefs);
        _goToHome();
        return;
      }
      setState(() {
        _checking = false;
        _downloading = true;
        _status = 'Downloading model...';
      });
      await ModelDownloader.downloadModel(onProgress: (p) {
        setState(() {
          _progress = p;
        });
      });
      await _setModelReady(prefs);
      _goToHome();
    } catch (e) {
      setState(() {
        _downloading = false;
        _checking = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _setModelReady([SharedPreferences? prefs]) async {
    final prefs0 = prefs ?? await SharedPreferences.getInstance();
    await prefs0.setBool('model_ready', true);
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Download Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkAndDownloadModel();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Preparing AI Model',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (_checking)
                Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking model file...',
                        style: TextStyle(fontSize: 16)),
                  ],
                )
              else if (_downloading) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 16),
                Text('${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                Text(_status),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
