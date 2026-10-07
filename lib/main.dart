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
      ],
      child: MaterialApp(
        title: 'Symfonium',
        theme: ThemeData.dark(),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symfonium — WebDAV 串流')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('連線至 WebDAV 伺服器播放高音質音樂'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final audio = context.read<SymfoniumAudioService>();
                await audio.initialize();
                // 範例：使用預設 WebDAV URL（實際使用時替換為你的伺服器）
                await audio.playFromWebDAV(
                  url: 'https://demo.webdav.org/music/test.flac',
                  headers: {'Authorization': 'Basic '},
                );
              },
              child: const Text('開始高音質播放'),
            ),
          ],
        ),
      ),
    );
  }
}
