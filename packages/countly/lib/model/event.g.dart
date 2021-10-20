// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
      key: json['key'] as String,
      count: json['count'] as int,
      sum: (json['sum'] as num).toDouble(),
      dow: json['dow'] as int,
      hour: json['hour'] as int,
      timestamp: json['timestamp'] as int,
      duration: (json['dur'] as num?)?.toDouble() ?? null,
      segmentation: json['segmentation'] as Map<String, dynamic>?,
    )..id = json['id'] as int?;

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'count': instance.count,
      'sum': instance.sum,
      'dur': instance.duration,
      'dow': instance.dow,
      'hour': instance.hour,
      'timestamp': instance.timestamp,
      'segmentation': instance.segmentation,
    };
