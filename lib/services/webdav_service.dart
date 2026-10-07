import 'dart:convert';

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

  /// 模擬目錄讀取（實際專案使用 webdav_client 的 PROPFIND）
  Future<List<String>> listMusicFiles(String remotePath) async {
    // 回傳範例檔案清單（實際專案替換為 webdav_client.readProps()）
    return [
      buildStreamUrl('$remotePath/01_intro.flac'),
      buildStreamUrl('$remotePath/02_main_track.mp3'),
    ];
  }

  bool isMusicFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['flac', 'mp3', 'aac', 'm4a', 'wav', 'ogg'].contains(ext);
  }
}
