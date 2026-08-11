# mixup_media_player

動画、音声、YouTube を `MixupMediaController` と `MixupMediaViewer` の共通 API で扱う
Flutter パッケージです。メディア種別と再生状態は Controller が一元管理し、利用側へ
各再生ライブラリ固有の Controller や Widget を公開しません。

## 環境構築

### 対応プラットフォーム

| プラットフォーム | 最小バージョン | audio | video | YouTube |
| --- | --- | :---: | :---: | :---: |
| Android | API 24 | ○ | ○ | ○ |
| iOS | 13.0 | ○ | ○ | ○ |
| macOS | 10.15 | ○ | ○ | ○ |
| Web | 下記ブラウザ要件を参照 | ○ | ○ | ○ |
| Linux | ディストリビューション依存 | ○ | × | × |
| Windows | Flutter のサポート対象 | ○ | × | × |

Android、iOS、macOS の最小バージョンは、利用している `flutter_soloud`、`video_player`、
`youtube_player_flutter` のうち最も高い要件です。Linux と Windows は
`video_player` および `youtube_player_flutter` の対象外であるため、音声のみ利用できます。

### 共通

利用するアプリの `pubspec.yaml` に、このパッケージと Flutter asset を追加してから
依存関係を取得します。ネットワークメディアだけを利用する場合、asset の設定は不要です。

```yaml
dependencies:
  mixup_media_player:
    path: ../../packages/mixup_media_player

flutter:
  assets:
    - assets/audio/
    - assets/video/
```

```sh
flutter pub get
```

ネットワークメディアには HTTPS URL を推奨します。HTTP URL を使用する場合は、Android の
cleartext traffic や Apple プラットフォームの App Transport Security を、接続先を限定して
許可してください。

### Android

`android/app/build.gradle.kts` の `minSdk` を 24 以上にし、ネットワークメディアを利用する場合は
`android/app/src/main/AndroidManifest.xml` にインターネット権限を追加します。

```kotlin
android {
    defaultConfig {
        minSdk = 24
    }
}
```

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

Deployment Target を 13.0 以上にします。CocoaPods でビルドする場合、`flutter_soloud` の
ネイティブコードをビルドするため CMake が必要です。

```sh
brew install cmake
```

Swift Package Manager を使用して Release archive でシンボル不足が発生する場合は、Xcode の
`Runner` → `Build Settings` → `Strip Style` を `Non-Global Symbols` に変更します。
HTTP URL を使用する場合は `ios/Runner/Info.plist` に接続先を限定した
`NSAppTransportSecurity` 設定を追加してください。HTTPS のみなら追加不要です。

### macOS

Deployment Target を 10.15 以上にします。ネットワークメディアを利用する場合は、Debug と
Release の両方の entitlement ファイルに次を追加します。

```xml
<key>com.apple.security.network.client</key>
<true/>
```

CocoaPods を使用する場合は `brew install cmake` が必要です。Swift Package Manager の
Release archive でシンボル不足が発生する場合は、iOS と同様に `Strip Style` を
`Non-Global Symbols` に変更します。

### Web

`web/index.html` で `flutter_bootstrap.js` より前に `flutter_soloud` の初期化スクリプトを
読み込みます。

```html
<script src="assets/packages/flutter_soloud/web/libflutter_soloud_plugin.js" defer></script>
<script src="assets/packages/flutter_soloud/web/init_module.dart.js" defer></script>
<script src="flutter_bootstrap.js" async></script>
```

`flutter_soloud` の WebAssembly は `SharedArrayBuffer` を使用するため、`--wasm` でビルドするか、
配信サーバーで cross-origin isolation を有効にします。後者では、すべてのレスポンスに次の
ヘッダーを設定します。

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

対応ブラウザは Safari 16.4+、Chrome 91+、Edge 91+、Firefox 89+ です。ネットワーク音声・動画の
配信元は CORS を許可している必要があります。また、ブラウザの autoplay 制限により、最初の
再生にはユーザー操作が必要になる場合があります。

### Linux

現在は音声のみ対応します。ALSA の開発ライブラリをインストールしてください。

```sh
# Debian / Ubuntu
sudo apt-get install libasound2-dev

# Arch Linux
sudo pacman -S alsa-lib

# OpenSUSE
sudo zypper install alsa-devel
```

Raspberry Pi など x86_64 以外では Xiph ライブラリもシステムへインストールし、
`TRY_SYSTEM_LIBS_FIRST=1 flutter run` でビルドする必要があります。

```sh
sudo apt-get install libflac-dev libogg-dev libopus-dev libvorbis-dev
TRY_SYSTEM_LIBS_FIRST=1 flutter run
```

### Windows

現在は音声のみ対応します。追加のプロジェクト設定は不要です。Flutter の Windows desktop
開発環境（Visual Studio の Desktop development with C++ を含む）を用意してください。

## 使用例

```dart
final controller = MixupMediaController(
  source: VideoMediaSource(
    data: NetworkVideoData(Uri.parse('https://example.com/video.mp4')),
  ),
);

MixupMediaViewer(controller: controller);

await controller.play();
await controller.skipForward(const Duration(seconds: 10));

controller.dispose();
```

`VideoData` と `AudioData` はネットワーク URL と Flutter asset に対応します。
YouTube には watch、share、shorts、embed の URL を `YouTubeMediaSource` で渡せます。

入力値は各 data/source の生成時に検証されます。無効な URL や空の asset path は
`MediaSourceValidationException` を送出します。準備失敗は `MediaLoadException`、再生操作の
失敗は `MediaPlaybackException` として `Future` から送出され、同じ例外を
`controller.state.failure?.exception` からも参照できます。

```dart
try {
  await controller.setSource(
    YouTubeMediaSource(url: Uri.parse(input)),
  );
} on MediaSourceValidationException catch (error) {
  print('${error.field}: ${error.message}');
} on MediaLoadException catch (error) {
  print(error.message);
}
```

## Example

example では URL とメディア種別を切り替えて各 backend を確認できます。メディア自体は
リポジトリに同梱していません。

```sh
cd packages/mixup_media_player/example
flutter run -d macos
```

プラットフォーム要件の詳細は、依存パッケージの公式ドキュメントも参照してください。

- [flutter_soloud setup](https://docs.page/alnitak/flutter_soloud_docs/get_started/setup)
- [video_player setup](https://pub.dev/packages/video_player#setup)
- [youtube_player_flutter platform requirements](https://pub.dev/packages/youtube_player_flutter#platform-requirements)
