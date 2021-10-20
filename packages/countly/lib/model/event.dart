import 'package:countly/model/entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

@JsonSerializable()
class Event extends Entity {
  @JsonKey(name: "key")
  final String key;

  @JsonKey(name: "count")
  final int count;

  @JsonKey(name: "sum")
  final double sum;

  @JsonKey(name: "dur")
  final double? duration;

  @JsonKey(name: "dow")
  late final int dow;

  @JsonKey(name: "hour")
  late final int hour;

  @JsonKey(name: "timestamp")
  late final int timestamp;

  @JsonKey(name: "segmentation")
  final Map<String, dynamic>? segmentation;

  Event._(this.key, this.count, this.sum, this.duration, this.dow, this.hour,
      this.timestamp, this.segmentation);
  Event({
    required this.key,
    required this.count,
    required this.sum,
    required this.dow,
    required this.hour,
    required this.timestamp,
    this.duration = null,
    this.segmentation,
  });

  @override
  String toString() {
    return 'Event{id: $id, key: $key, count: $count, sum: $sum, duration: $duration, dow: $dow, hour: $hour, timestamp: $timestamp, segmentation: $segmentation}';
  }

  @override
  Map<String, dynamic> toJson() => _$EventToJson(this);

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
