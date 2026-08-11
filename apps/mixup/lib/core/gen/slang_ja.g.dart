///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'slang.g.dart';

// Path: <root>
typedef TranslationsJa = Translations; // ignore: unused_element

class Translations with BaseTranslations<AppLocale, Translations> {
  /// Returns the current translations of the given [context].
  ///
  /// Usage:
  /// final t = Translations.of(context);
  static Translations of(BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       $meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.ja,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           );

  /// Metadata for the translations of <ja>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  late final Translations _root = this; // ignore: unused_field

  Translations $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => Translations(meta: meta ?? this.$meta);

  // Translations
  late final Translations$practice$ja practice = Translations$practice$ja._(
    _root,
  );
}

// Path: practice
class Translations$practice$ja {
  Translations$practice$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  late final Translations$practice$common$ja common =
      Translations$practice$common$ja._(_root);
  late final Translations$practice$errors$ja errors =
      Translations$practice$errors$ja._(_root);
  late final Translations$practice$scaffold$ja scaffold =
      Translations$practice$scaffold$ja._(_root);
  late final Translations$practice$player$ja player =
      Translations$practice$player$ja._(_root);
  late final Translations$practice$timeline$ja timeline =
      Translations$practice$timeline$ja._(_root);
  late final Translations$practice$intervalForm$ja intervalForm =
      Translations$practice$intervalForm$ja._(_root);
  late final Translations$practice$lyrics$ja lyrics =
      Translations$practice$lyrics$ja._(_root);
  late final Translations$practice$mix$ja mix = Translations$practice$mix$ja._(
    _root,
  );
}

// Path: practice.common
class Translations$practice$common$ja {
  Translations$practice$common$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '再試行'
  String get retry => '再試行';

  /// ja: '複製'
  String get duplicate => '複製';

  /// ja: '削除'
  String get delete => '削除';

  /// ja: '区間を編集'
  String get editInterval => '区間を編集';

  /// ja: '0.1秒前へ移動'
  String get moveBack => '0.1秒前へ移動';

  /// ja: '0.1秒後へ移動'
  String get moveForward => '0.1秒後へ移動';
}

// Path: practice.errors
class Translations$practice$errors$ja {
  Translations$practice$errors$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '歌詞行を選択してください。'
  String get selectLyric => '歌詞行を選択してください。';

  /// ja: '編集中のデータがありません。'
  String get noData => '編集中のデータがありません。';

  /// ja: '音源の読み込み完了後に登録してください。'
  String get mediaNotReady => '音源の読み込み完了後に登録してください。';

  /// ja: '開始 < 終了とし、音源の範囲内で指定してください。'
  String get invalidInterval => '開始 < 終了とし、音源の範囲内で指定してください。';

  /// ja: '時刻を秒で入力してください。'
  String get invalidTime => '時刻を秒で入力してください。';

  /// ja: 'MIXを選択してください。'
  String get selectMix => 'MIXを選択してください。';
}

// Path: practice.scaffold
class Translations$practice$scaffold$ja {
  Translations$practice$scaffold$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '元に戻す'
  String get undo => '元に戻す';

  /// ja: 'やり直す'
  String get redo => 'やり直す';

  /// ja: '保存'
  String get save => '保存';

  /// ja: '1. 歌詞・間奏'
  String get timingStep => '1. 歌詞・間奏';

  /// ja: '2. MIX設定'
  String get mixStep => '2. MIX設定';

  /// ja: 'lyrics.md の歌詞行が更新されています。既存区間は保持されています。内容を確認して再紐付けしてください。'
  String get lyricsChanged =>
      'lyrics.md の歌詞行が更新されています。既存区間は保持されています。内容を確認して再紐付けしてください。';

  /// ja: '編集パネルで再紐付け'
  String get relinkInEditor => '編集パネルで再紐付け';

  /// ja: '保存に失敗しました。編集内容は保持されています。 $error'
  String saveFailed({required Object error}) =>
      '保存に失敗しました。編集内容は保持されています。\n${error}';

  late final Translations$practice$scaffold$status$ja status =
      Translations$practice$scaffold$status$ja._(_root);
}

// Path: practice.player
class Translations$practice$player$ja {
  Translations$practice$player$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '音源を読み込んでいます'
  String get loading => '音源を読み込んでいます';

  /// ja: '音源の読み込み・再生に失敗しました $error'
  String failure({required Object error}) => '音源の読み込み・再生に失敗しました\n${error}';

  /// ja: '5秒戻る'
  String get backFive => '5秒戻る';

  /// ja: '一時停止'
  String get pause => '一時停止';

  /// ja: '再生'
  String get play => '再生';

  /// ja: '5秒進む'
  String get forwardFive => '5秒進む';

  late final Translations$practice$player$status$ja status =
      Translations$practice$player$status$ja._(_root);
}

// Path: practice.timeline
class Translations$practice$timeline$ja {
  Translations$practice$timeline$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: 'タイムライン'
  String get title => 'タイムライン';

  /// ja: '歌詞'
  String get lyricsTrack => '歌詞';

  /// ja: 'MIX'
  String get mixTrack => 'MIX';

  /// ja: '$label（タップでここから再生、ドラッグで移動）'
  String dragHint({required Object label}) => '${label}（タップでここから再生、ドラッグで移動）';
}

// Path: practice.intervalForm
class Translations$practice$intervalForm$ja {
  Translations$practice$intervalForm$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '開始（秒）'
  String get startSeconds => '開始（秒）';

  /// ja: '現在位置を開始に設定'
  String get setCurrentStart => '現在位置を開始に設定';

  /// ja: '終了（秒）'
  String get endSeconds => '終了（秒）';

  /// ja: '現在位置を終了に設定'
  String get setCurrentEnd => '現在位置を終了に設定';
}

// Path: practice.lyrics
class Translations$practice$lyrics$ja {
  Translations$practice$lyrics$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '未同期'
  String get unsynced => '未同期';

  /// ja: '$count区間'
  String intervalCount({required Object count}) => '${count}区間';

  /// ja: '区間の編集'
  String get editorTitle => '区間の編集';

  /// ja: '歌詞行を選択してください'
  String get selectLine => '歌詞行を選択してください';

  /// ja: '歌詞区間を追加'
  String get addInterval => '歌詞区間を追加';

  /// ja: '間奏'
  String get interlude => '間奏';

  /// ja: '間奏ラベル'
  String get interludeLabel => '間奏ラベル';

  /// ja: '歌詞なし区間（間奏）を追加'
  String get addInterlude => '歌詞なし区間（間奏）を追加';

  /// ja: '登録済みの間奏'
  String get savedInterludes => '登録済みの間奏';

  /// ja: '再紐付けが必要な歌詞区間'
  String get relinkRequired => '再紐付けが必要な歌詞区間';

  /// ja: '歌詞の更新を確認済みにする'
  String get confirmNoIntervals => '歌詞の更新を確認済みにする';

  /// ja: '紐付け先'
  String get relinkTarget => '紐付け先';

  /// ja: '曲バンドルの読み込みに失敗しました。lyrics.md、音源、設定を確認してください。 $error'
  String loadFailure({required Object error}) =>
      '曲バンドルの読み込みに失敗しました。lyrics.md、音源、設定を確認してください。\n${error}';
}

// Path: practice.mix
class Translations$practice$mix$ja {
  Translations$practice$mix$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '読み込みに失敗しました。再試行 $error'
  String loadFailure({required Object error}) => '読み込みに失敗しました。再試行\n${error}';

  /// ja: 'MIX名・本文・小節数で検索'
  String get search => 'MIX名・本文・小節数で検索';

  /// ja: '$bars小節 · $call'
  String barsAndCall({required Object bars, required Object call}) =>
      '${bars}小節 · ${call}';

  /// ja: '選択区間のMIX'
  String get editorTitle => '選択区間のMIX';

  /// ja: '左の一覧からMIXを選択してください。'
  String get selectFromList => '左の一覧からMIXを選択してください。';

  /// ja: 'この区間へMIXを設定'
  String get assign => 'この区間へMIXを設定';

  /// ja: 'メモ（任意）'
  String get note => 'メモ（任意）';

  /// ja: 'MIX開始時に自動で一時停止'
  String get autoPause => 'MIX開始時に自動で一時停止';

  /// ja: '設定済みMIX ($count)'
  String assignedCount({required Object count}) => '設定済みMIX (${count})';

  /// ja: '間奏・歌詞の間'
  String get betweenLyrics => '間奏・歌詞の間';

  /// ja: '歌詞中: $lyrics'
  String duringLyrics({required Object lyrics}) => '歌詞中: ${lyrics}';

  /// ja: '参照切れ: $mixId'
  String missingReference({required Object mixId}) => '参照切れ: ${mixId}';
}

// Path: practice.scaffold.status
class Translations$practice$scaffold$status$ja {
  Translations$practice$scaffold$status$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '保存済み'
  String get saved => '保存済み';

  /// ja: '未保存の変更あり'
  String get dirty => '未保存の変更あり';

  /// ja: '保存中…'
  String get saving => '保存中…';

  /// ja: '保存失敗'
  String get failed => '保存失敗';
}

// Path: practice.player.status
class Translations$practice$player$status$ja {
  Translations$practice$player$status$ja._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// ja: '再生中'
  String get playing => '再生中';

  /// ja: '一時停止中'
  String get paused => '一時停止中';

  /// ja: '停止中'
  String get stopped => '停止中';

  /// ja: '再生完了'
  String get completed => '再生完了';
}
