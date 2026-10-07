import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/webdav_service.dart';
import 'services/audio_player_service.dart';

void main() {
  runApp(const SymfoniumApp());
}

class SymfoniumApp extends StatelessWidget {
  const SymfoniumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SymfoniumAudioService()),
        ChangeNotifierProvider(create: (_) => WebDAVConfigService()),
      ],
      child: MaterialApp(
        title: 'Symfonium',
        theme: ThemeData.dark(),
        home: const WebDAVConfigScreen(),
      ),
    );
  }
}

/// WebDAV 設定儲存服務
class WebDAVConfigService extends ChangeNotifier {
  String _serverUrl = '';
  String _username = '';
  String _password = '';
  String _remotePath = '/';

  String get serverUrl => _serverUrl;
  String get username => _username;
  String get password => _password;
  String get remotePath => _remotePath;

  bool get isConfigured => _serverUrl.isNotEmpty && _username.isNotEmpty;

  void updateConfig({
    String? serverUrl,
    String? username,
    String? password,
    String? remotePath,
  }) {
    if (serverUrl != null) _serverUrl = serverUrl;
    if (username != null) _username = username;
    if (password != null) _password = password;
    if (remotePath != null) _remotePath = remotePath;
    notifyListeners();
  }

  void clear() {
    _serverUrl = '';
    _username = '';
    _password = '';
    _remotePath = '/';
    notifyListeners();
  }
}

/// WebDAV 設定畫面
class WebDAVConfigScreen extends StatefulWidget {
  const WebDAVConfigScreen({super.key});

  @override
  State<WebDAVConfigScreen> createState() => _WebDAVConfigScreenState();
}

class _WebDAVConfigScreenState extends State<WebDAVConfigScreen> {
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _pathController = TextEditingController(text: '/');
  final _formKey = GlobalKey<FormState>();
  bool _testing = false;

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<WebDAVConfigService>();

    if (config.isConfigured) {
      return const FileBrowserScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Symfonium — WebDAV 設定')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'WebDAV 伺服器 URL',
                  hintText: 'https://your-server.com/webdav/',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? '請輸入 URL' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: '使用者名稱',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? '請輸入帳號' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: '密碼',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v!.isEmpty ? '請輸入密碼' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pathController,
                decoration: const InputDecoration(
                  labelText: '遠端音樂路徑',
                  hintText: '/music/',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _testing ? null : _testAndSave,
                child: _testing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('測試連線並儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _testing = true);

    try {
      // 測試連線：列出根目錄
      final service = WebDAVMusicService(
        serverUrl: _urlController.text.trim(),
        username: _userController.text.trim(),
        password: _passController.text.trim(),
      );
      await service.listMusicFiles(_pathController.text.trim());

      // 成功 → 儲存並進入檔案瀏覽器
      context.read<WebDAVConfigService>().updateConfig(
        serverUrl: _urlController.text.trim(),
        username: _userController.text.trim(),
        password: _passController.text.trim(),
        remotePath: _pathController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FileBrowserScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('連線失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }
}

/// 檔案瀏覽器畫面
class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  late Future<List<MusicFile>> _futureFiles;
  String _currentPath = '/';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    final config = context.read<WebDAVConfigService>();
    final service = WebDAVMusicService(
      serverUrl: config.serverUrl,
      username: config.username,
      password: config.password,
    );
    setState(() {
      _futureFiles = service.listMusicFiles(_currentPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<WebDAVConfigService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('音樂目錄: $_currentPath'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              config.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WebDAVConfigScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MusicFile>>(
        future: _futureFiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return const Center(child: Text('此目錄無音樂檔案'));
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(file.name),
                subtitle: Text('${_formatSize(file.size)} • ${file.modifiedTime}'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => _playFile(file),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _playFile(MusicFile file) async {
    final config = context.read<WebDAVConfigService>();
    final audio = context.read<SymfoniumAudioService>();

    final streamUrl = WebDAVMusicService(
      serverUrl: config.serverUrl,
      username: config.username,
      password: config.password,
    ).buildStreamUrl(file.relativePath);

    final headers = WebDAVMusicService(
      serverUrl: config.serverUrl,
      username: config.username,
      password: config.password,
    ).getAuthHeaders();

    try {
      await audio.playFromWebDAV(url: streamUrl, headers: headers);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (_) => PlayerBottomSheet(audio: audio, trackName: file.name),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 播放器底部彈出控制器
class PlayerBottomSheet extends StatelessWidget {
  final SymfoniumAudioService audio;
  final String trackName;

  const PlayerBottomSheet({super.key, required this.audio, required this.trackName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trackName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<Duration>(
            stream: audio.positionStream,
            builder: (context, snapshot) {
              final pos = snapshot.data ?? Duration.zero;
              final dur = audio.duration;
              return Column(
                children: [
                  Slider(
                    value: pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble()),
                    max: dur.inMilliseconds.toDouble(),
                    onChanged: (v) => audio.seek(Duration(milliseconds: v.toInt())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(pos)),
                      Text(_formatDuration(dur)),
                    ],
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.replay_10), onPressed: () => audio.seek(audio.position - const Duration(seconds: 10))),
              IconButton(
                icon: StreamBuilder<bool>(
                  stream: audio.playingStream,
                  builder: (_, snap) => Icon(snap.data == true ? Icons.pause : Icons.play_arrow),
                ),
                iconSize: 36,
                onPressed: () => audio.playing ? audio.pause() : audio.resume(),
              ),
              IconButton(icon: const Icon(Icons.forward_10), onPressed: () => audio.seek(audio.position + const Duration(seconds: 10))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
