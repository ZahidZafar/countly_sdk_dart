// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteConfig _$RemoteConfigFromJson(Map<String, dynamic> json) => RemoteConfig(
      data: json['data'] as String,
    )..id = json['id'] as int?;

Map<String, dynamic> _$RemoteConfigToJson(RemoteConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data': instance.data,
    };
