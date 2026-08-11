import 'package:mixup/core/gen/slang.g.dart';
import 'package:mixup/presentation/features/practice/controllers/practice_session.dart';

/// Converts a feature error code through the localization source of truth.
String practiceEditErrorText(PracticeEditError error) => switch (error) {
  PracticeEditError.selectLyric => t.practice.errors.selectLyric,
  PracticeEditError.selectMix => t.practice.errors.selectMix,
  PracticeEditError.noData => t.practice.errors.noData,
  PracticeEditError.mediaNotReady => t.practice.errors.mediaNotReady,
  PracticeEditError.invalidInterval => t.practice.errors.invalidInterval,
};
