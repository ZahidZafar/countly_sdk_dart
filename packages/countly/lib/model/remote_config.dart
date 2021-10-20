import 'package:countly/model/entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remote_config.g.dart';

@JsonSerializable()
class RemoteConfig extends Entity {
  final String data;

  RemoteConfig({
    required this.data,
  });

  @override
  Map<String, dynamic> toJson() => _$RemoteConfigToJson(this);

  factory RemoteConfig.fromJson(Map<String, dynamic> json) =>
      _$RemoteConfigFromJson(json);
}
