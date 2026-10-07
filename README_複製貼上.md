# Symfonium iOS — 完整專案結構（可直接複製貼上）

路徑：`C:\Users\jimmy.cc.lin\AppData\Local\hermes\cache\scratch\symfonium-full-project\`

---

## 複製貼上步驟

1. **建立 Flutter 專案**（如果還沒有）：
   ```bash
   flutter create symfonium_ios
   cd symfonium_ios
   ```

2. **覆蓋檔案**（將本目錄內容直接貼入）：
   - `pubspec.yaml` → 專案根目錄（替換原檔）
   - `.github/workflows/build_ios.yml` → 專案根目錄 `.github/workflows/`
   - `lib/main.dart` → 覆蓋 `lib/main.dart`
   - `lib/services/webdav_service.dart` → 新增至 `lib/services/`
   - `lib/services/audio_player_service.dart` → 新增至 `lib/services/`
   - `ios/Runner/Info.plist_snippet` → 將內容合併至 `ios/Runner/Info.plist`

3. **安裝依賴**：
   ```bash
   flutter pub get
   ```

4. **推到 GitHub 觸發 `.ipa` 編譯**：
   ```bash
   git init
   git add .
   git commit -m "init symfonium ios"
   # 設定遠端後推送
   ```

---

## 專案檔案清單（全部已存在於本目錄）

| 檔案 | 用途 |
|---|---|
| `pubspec.yaml` | 依賴（audio_service / just_audio / webdav_client）|
| `lib/main.dart` | App 入口與主畫面 |
| `lib/services/webdav_service.dart` | WebDAV 連線與串流 URL |
| `lib/services/audio_player_service.dart` | 背景播放 + Lock Screen 控制 |
| `.github/workflows/build_ios.yml` | GitHub Actions 雲端編譯 `.ipa` |
| `ios/Runner/Info.plist_snippet` | 背景音訊模式設定 |

---

## 如何下載 `.ipa`

1. 將本專案推到 GitHub → 觸發 Actions。
2. 完成後，前往 GitHub Repo → **Actions** → 下載 Artifact：`symfonium-ios-ipa-unsigned`。
3. 使用 **AltStore** 或 **SideStore** 側載到 iPhone 17 Pro（參考 `4_免費實機安裝指南.md`）。
