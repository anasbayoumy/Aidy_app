import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'utils/app_constants.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const ProviderScope(child: AidyApp()));
}

class AidyApp extends StatelessWidget {
  const AidyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F51B5),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
            ),
          ),
        ),
        home: const HomeScreen());
  }
}

// Add a stateful widget for voice recording
class VoiceRecorderWidget extends StatefulWidget {
  final void Function(String? path) onRecordingComplete;
  const VoiceRecorderWidget({required this.onRecordingComplete, super.key});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _filePath;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  late String _wavPath;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<String> _getWavPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/voice_input.wav';
  }

  Future<void> _startRecording() async {
    _wavPath = await _getWavPath();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 16000,
      ),
      path: _wavPath,
    );
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _filePath = null;
    });
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _filePath = path;
    });
    widget.onRecordingComplete(path);
  }

  Future<void> _restartRecording() async {
    await _recorder.stop();
    await _startRecording();
  }

  Future<void> _playRecording() async {
    if (_filePath == null) return;
    await _player.setFilePath(_filePath!);
    setState(() {
      _isPlaying = true;
    });
    _player.play();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _clearRecording() {
    setState(() {
      _filePath = null;
    });
    widget.onRecordingComplete(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isRecording && _filePath == null)
          ElevatedButton.icon(
            icon: Icon(Icons.mic),
            label: Text('Record Voice'),
            onPressed: _startRecording,
          ),
        if (_isRecording) ...[
          Row(
            children: [
              ElevatedButton.icon(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(_isPaused ? 'Resume' : 'Pause'),
                onPressed: _isPaused ? _resumeRecording : _pauseRecording,
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.stop),
                label: Text('Stop'),
                onPressed: _stopRecording,
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.restart_alt),
                label: Text('Restart'),
                onPressed: _restartRecording,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Recording...'),
          ),
        ],
        if (_filePath != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Stop' : 'Play'),
                    onPressed: _isPlaying ? _stopPlayback : _playRecording,
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Clear'),
                    onPressed: _clearRecording,
                  ),
                ],
              ),
              Text('Voice file: ${_filePath!.split('/').last}'),
            ],
          ),
      ],
    );
  }
}
