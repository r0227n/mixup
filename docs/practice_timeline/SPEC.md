# 練習タイムライン仕様

## 正の分離

- `lyrics/songs/<song-slug>/lyrics.md` は歌詞本文と音源メタデータの正であり、練習画面から変更しない。
- `lyrics/songs/<song-slug>/practice-timeline.json` は同期区間、間奏区間、MIX参照、編集日時の正とする。
- `mixs/` はMIX名と本文の正とし、タイムラインにはOKF文書の相対パスだけを `mixId` として保存する。
- 保存前の変更は `PracticeSession` のdraftだけが所有する。

## JSON v1

```json
{
  "version": 1,
  "songId": "utage",
  "audio": {
    "path": "audio/reference.mp3",
    "durationMs": 180000
  },
  "lyricsFingerprint": "12ab34cd",
  "editedAt": "2026-08-11T12:00:00.000Z",
  "lyricIntervals": [
    {
      "id": "lyric-1",
      "lyricId": "line-0001",
      "text": "歌詞本文",
      "startMs": 1000,
      "endMs": 3200
    }
  ],
  "interludes": [
    {
      "id": "interlude-1",
      "label": "間奏",
      "startMs": 5000,
      "endMs": 12000
    }
  ],
  "mixIntervals": [
    {
      "id": "mix-1",
      "mixId": "8/8_konton.md",
      "note": "任意メモ",
      "startMs": 2500,
      "endMs": 9000
    }
  ]
}
```

全区間は `0 <= startMs < endMs <= audio.durationMs` を満たす。歌詞区間とMIX区間の重複は許可する。
表示用の「歌詞中」「歌詞の間」「間奏」は区間の重なりから導出し、保存しない。

`lyricId` は `# 歌詞` 配下の空行を除く行順から `line-0001` の形式で生成する。
全歌詞行から生成した `lyricsFingerprint` が現在値と異なる場合、保存済み区間を削除・移動せず要確認として表示する。
旧IDの位置にある本文が一致しない区間は自動確定せず、ユーザーが区間ごとに現在の歌詞行を選択して再紐付けする。

## 保存

デスクトップでは同じ曲ディレクトリへ一時ファイルを書き切り、`practice-timeline.json` へrenameして置換する。
失敗時は一時ファイルを除去し、画面上のdraftを保持して再試行できるようにする。
保存処理中に追加編集された場合、完了した保存snapshotで新しいdraftを上書きせず、未保存状態として保持する。

WebではローカルOKFバンドルの読み書きが未対応であり、現時点では回復可能な非対応エラーを表示する。
レスポンシブな2画面レイアウト自体はWebでも構築できるが、ブラウザ用のファイル選択・書き戻しadapterは別途必要である。
