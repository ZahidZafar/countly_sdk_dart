// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Request _$RequestFromJson(Map<String, dynamic> json) => Request(
      data: json['data'] as String,
      timestamp: json['timestamp'] as int,
    )..id = json['id'] as int?;

Map<String, dynamic> _$RequestToJson(Request instance) => <String, dynamic>{
      'id': instance.id,
      'data': instance.data,
      'timestamp': instance.timestamp,
    };
