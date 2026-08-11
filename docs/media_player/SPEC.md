# メディアプレイヤーパッケージ仕様

## 目的

動画、音声、YouTube の各メディアを、呼び出し側が一貫した操作 API と一つの Viewer で扱える Flutter パッケージを提供する。

呼び出し側はメディア種別ごとの再生ライブラリや個別の Widget を直接扱わない。再生対象と再生状態は Controller を唯一の正とし、Viewer はその状態を表示する。

## 公開する主要要素

パッケージは少なくとも次の公開 API を提供する。

- `MixupMediaController`: 再生対象、再生状態、再生操作を管理する。
- `MixupMediaViewer`: 呼び出し側が配置する唯一の Viewer。再生対象の種別に応じて内部の Viewer を選択する。
- `MediaSource`: Controller に渡す再生対象を表す sealed class。

## メディア入力モデル

`MixupMediaController` は、再生対象を `source` プロパティとして受け取る。`source` の型は sealed class `MediaSource` とし、未対応のメディア種別を外部パッケージから追加できないようにする。

```dart
sealed class MediaSource {
  const MediaSource();
}

final class VideoMediaSource extends MediaSource {
  const VideoMediaSource({required this.data});

  final VideoData data;
}

final class AudioMediaSource extends MediaSource {
  const AudioMediaSource({required this.data});

  final AudioData data;
}

extension type VideoId(String value) {}

final class YouTubeMediaSource extends MediaSource {
  factory YouTubeMediaSource({required Uri url});

  final Uri url;
  final VideoId videoId;
}
```

- `VideoMediaSource` は動画データを表す。`VideoData` の具体的な表現（ファイル、URI、バイト列など）は、採用する `video_player` の入力要件に合わせてパッケージ内で定義する。
- `AudioMediaSource` は音声データを表す。`AudioData` の具体的な表現は、`flutter_soloud` の入力要件に合わせてパッケージ内で定義する。
- `YouTubeMediaSource` は YouTube の URL を表す。URL の妥当性確認と、再生に必要な ID の抽出はパッケージ内で行い、抽出後の ID は `VideoId` として保持する。

メディアの種別判定は `MediaSource` のサブタイプだけを正とする。呼び出し側が別途フラグや enum を渡して、種別の情報を重複保持してはならない。

## Controller の責務

`MixupMediaController` は状態と操作の唯一の正であり、次を担う。

- `MediaSource source` を保持し、必要な再生実装を準備・破棄する。
- 再生、一時停止、停止、指定秒数の前方・後方スキップを提供する。
- 再生状態、現在位置、再生時間、読み込み状態、エラー状態を通知可能な形で管理する。
- メディア実装固有のエラーを、利用者が復旧可能なアプリ向け状態へ変換する。
- Controller の破棄時に、内部プレイヤーと関連リソースを確実に解放する。
- 入力不正、読み込み失敗、再生失敗をパッケージ独自の `MediaPlayerException` サブタイプへ
  変換し、操作 API の `Future` とエラー状態の両方から呼び出し側が判別できるようにする。

操作は少なくとも次を持つ。

```dart
Future<void> play();
Future<void> pause();
Future<void> stop();
Future<void> skipForward(Duration offset);
Future<void> skipBackward(Duration offset);
```

`stop()` は停止状態へ遷移し、再生位置を先頭へ戻す。停止中に `play()` すると先頭から再生する。範囲外へのスキップは、先頭または再生可能な末尾へ丸める。

## Viewer の責務

呼び出し側は `MixupMediaViewer(controller: controller)` のみを配置する。`MixupMediaViewer` は `controller.source` を分岐し、対応する内部 Viewer を表示する。

```text
MixupMediaViewer
├── VideoMediaSource   -> VideoViewer
├── AudioMediaSource   -> AudioViewer
└── YouTubeMediaSource -> YouTubeViewer
```

Viewer は Controller が通知する状態を UI に反映する。対象は再生・停止・一時停止の状態、現在位置、再生時間、読み込み中、エラー、および操作可能性である。

Viewer は再生状態の正を持たず、操作が行われた場合は必ず Controller の API を呼び出す。再生・停止などのビジネスロジックを Widget の `build` 内に置かない。

## 個別 Viewer と再生ライブラリ

個別 Viewer はすべて独立したファイルに実装し、呼び出し側から直接使用しない。

| 内部 Viewer | 実装ファイル | 使用ライブラリ | 用途 |
| --- | --- | --- | --- |
| `VideoViewer` | `lib/src/viewer/video_viewer.dart` | [`video_player`](https://pub.dev/packages/video_player) | 動画データの表示・再生 |
| `YouTubeViewer` | `lib/src/viewer/youtube_viewer.dart` | [`youtube_player_flutter`](https://pub.dev/packages/youtube_player_flutter) | YouTube URL の表示・再生 |
| `AudioViewer` | `lib/src/viewer/audio_viewer.dart` | [`flutter_soloud`](https://pub.dev/packages/flutter_soloud) | 音声データの再生 UI |

`MixupMediaViewer` 自身は `lib/src/viewer/mixup_media_viewer.dart` に実装する。ここだけが `MediaSource` を分岐し、各個別 Viewer を組み立てる。

## 依存関係と境界

```text
呼び出し側
  ├── MixupMediaController <── MediaSource
  └── MixupMediaViewer(controller)
          └── MediaSource の型で内部 Viewer を分岐
                ├── VideoViewer   ── video_player
                ├── YouTubeViewer ── youtube_player_flutter
                └── AudioViewer   ── flutter_soloud
```

- `lib/src/` の個別 Viewer、各ライブラリ固有の Controller、初期化方法は公開 API としない。
- `MixupMediaController` と `MixupMediaViewer` は各再生ライブラリの詳細に依存しない公開契約を持つ。
- メディア種別を追加する場合は、`MediaSource` のサブタイプ、Controller の対応実装、個別 Viewer、`MixupMediaViewer` の分岐を同じ変更で追加する。

## 状態の扱い

少なくとも次の状態を UI で区別できるようにする。

- 準備前または読み込み中
- 再生中
- 一時停止中
- 停止中
- 再生完了
- エラー（復旧のための次の操作を含む）

メディア切替中や Controller の破棄後に、以前の非同期処理の結果が新しい再生対象の状態を上書きしてはならない。

## 入力検証と例外

- ネットワーク動画・音声 URL は絶対 HTTP / HTTPS URL でなければならない。
- asset path は空文字または空白だけであってはならない。
- YouTube URL は対応形式であり、動画 ID を抽出できなければならない。
- 入力不正は `MediaSourceValidationException`、準備失敗は `MediaLoadException`、再生操作失敗は
  `MediaPlaybackException` とする。いずれも `MediaPlayerException` を基底型とする。
- plugin 固有例外は独自例外の `cause` に保持し、公開 API の例外型として直接送出しない。

## 非対象

- 再生ライブラリの API をそのまま外部へ公開すること
- Viewer ごとに独自の再生状態を保持すること
- 音源・動画ファイル、YouTube のコンテンツをリポジトリへ同梱すること
