// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContentSettings {

 String get songsPath; String get mixesPath;
/// Create a copy of ContentSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentSettingsCopyWith<ContentSettings> get copyWith => _$ContentSettingsCopyWithImpl<ContentSettings>(this as ContentSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentSettings&&(identical(other.songsPath, songsPath) || other.songsPath == songsPath)&&(identical(other.mixesPath, mixesPath) || other.mixesPath == mixesPath));
}


@override
int get hashCode => Object.hash(runtimeType,songsPath,mixesPath);

@override
String toString() {
  return 'ContentSettings(songsPath: $songsPath, mixesPath: $mixesPath)';
}


}

/// @nodoc
abstract mixin class $ContentSettingsCopyWith<$Res>  {
  factory $ContentSettingsCopyWith(ContentSettings value, $Res Function(ContentSettings) _then) = _$ContentSettingsCopyWithImpl;
@useResult
$Res call({
 String songsPath, String mixesPath
});




}
/// @nodoc
class _$ContentSettingsCopyWithImpl<$Res>
    implements $ContentSettingsCopyWith<$Res> {
  _$ContentSettingsCopyWithImpl(this._self, this._then);

  final ContentSettings _self;
  final $Res Function(ContentSettings) _then;

/// Create a copy of ContentSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? songsPath = null,Object? mixesPath = null,}) {
  return _then(_self.copyWith(
songsPath: null == songsPath ? _self.songsPath : songsPath // ignore: cast_nullable_to_non_nullable
as String,mixesPath: null == mixesPath ? _self.mixesPath : mixesPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentSettings].
extension ContentSettingsPatterns on ContentSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentSettings value)  $default,){
final _that = this;
switch (_that) {
case _ContentSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ContentSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String songsPath,  String mixesPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentSettings() when $default != null:
return $default(_that.songsPath,_that.mixesPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String songsPath,  String mixesPath)  $default,) {final _that = this;
switch (_that) {
case _ContentSettings():
return $default(_that.songsPath,_that.mixesPath);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String songsPath,  String mixesPath)?  $default,) {final _that = this;
switch (_that) {
case _ContentSettings() when $default != null:
return $default(_that.songsPath,_that.mixesPath);case _:
  return null;

}
}

}

/// @nodoc


class _ContentSettings implements ContentSettings {
  const _ContentSettings({required this.songsPath, required this.mixesPath});
  

@override final  String songsPath;
@override final  String mixesPath;

/// Create a copy of ContentSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentSettingsCopyWith<_ContentSettings> get copyWith => __$ContentSettingsCopyWithImpl<_ContentSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentSettings&&(identical(other.songsPath, songsPath) || other.songsPath == songsPath)&&(identical(other.mixesPath, mixesPath) || other.mixesPath == mixesPath));
}


@override
int get hashCode => Object.hash(runtimeType,songsPath,mixesPath);

@override
String toString() {
  return 'ContentSettings(songsPath: $songsPath, mixesPath: $mixesPath)';
}


}

/// @nodoc
abstract mixin class _$ContentSettingsCopyWith<$Res> implements $ContentSettingsCopyWith<$Res> {
  factory _$ContentSettingsCopyWith(_ContentSettings value, $Res Function(_ContentSettings) _then) = __$ContentSettingsCopyWithImpl;
@override @useResult
$Res call({
 String songsPath, String mixesPath
});




}
/// @nodoc
class __$ContentSettingsCopyWithImpl<$Res>
    implements _$ContentSettingsCopyWith<$Res> {
  __$ContentSettingsCopyWithImpl(this._self, this._then);

  final _ContentSettings _self;
  final $Res Function(_ContentSettings) _then;

/// Create a copy of ContentSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? songsPath = null,Object? mixesPath = null,}) {
  return _then(_ContentSettings(
songsPath: null == songsPath ? _self.songsPath : songsPath // ignore: cast_nullable_to_non_nullable
as String,mixesPath: null == mixesPath ? _self.mixesPath : mixesPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
