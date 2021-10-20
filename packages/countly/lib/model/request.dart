import 'package:countly/model/entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class Request extends Entity {
  final String data;
  final int timestamp;

  Request({
    required this.data,
    required this.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => _$RequestToJson(this);

  factory Request.fromJson(Map<String, dynamic> json) =>
      _$RequestFromJson(json);
}
