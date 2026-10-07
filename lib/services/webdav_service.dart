import 'dart:convert';

class MusicFile {
  final String name;
  final String relativePath;
  final int size;
  final String modifiedTime;

  MusicFile({
    required this.name,
    required this.relativePath,
    required this.size,
    required this.modifiedTime,
  });
}

class WebDAVMusicService {
  final String serverUrl;
  final String username;
  final String password;

  WebDAVMusicService({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  /// 建立已驗證的串流 URL（含 Basic Auth Header）
  String buildStreamUrl(String relativePath) {
    final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    final path = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return '$base$path';
  }

  /// 取得串流播放所需的 HTTP Headers
  Map<String, String> getAuthHeaders() {
    final encoded = base64Encode(utf8.encode('$username:$password'));
    return {'Authorization': 'Basic $encoded'};
  }

  /// 讀取音樂目錄（實際專案使用 webdav_client 的 PROPFIND）
  Future<List<MusicFile>> listMusicFiles(String remotePath) async {
    // 回傳範例檔案清單（實際專案替換為 webdav_client.readProps()）
    final now = DateTime.now().toIso8601String();
    return [
      MusicFile(
        name: '01_intro.flac',
        relativePath: '$remotePath/01_intro.flac',
        size: 45000000,
        modifiedTime: now,
      ),
      MusicFile(
        name: '02_main_track.mp3',
        relativePath: '$remotePath/02_main_track.mp3',
        size: 12000000,
        modifiedTime: now,
      ),
    ];
  }

  bool isMusicFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['flac', 'mp3', 'aac', 'm4a', 'wav', 'ogg'].contains(ext);
  }
}
