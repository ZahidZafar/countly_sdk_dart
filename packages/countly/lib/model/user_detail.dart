import 'package:countly/model/entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_detail.g.dart';

@JsonSerializable()
class UserDetail extends Entity {
  @JsonKey(name: "name")
  late String? name;
  @JsonKey(name: "username")
  late String? username;
  @JsonKey(name: "email")
  late String? email;
  @JsonKey(name: "organization")
  late String? organization;
  @JsonKey(name: "phone")
  late String? phone;

//Web URL to picture
//"https://pbs.twimg.com/profile_images/1442562237/012_n_400x400.jpg",

  @JsonKey(name: "picture")
  late String? pictureUrl;

  @JsonKey(name: "gender")
  late String? gender;

  @JsonKey(name: "byear")
  late String? birthYear;

  @JsonKey(name: "custom")
  Map<String, dynamic>? custom;

  UserDetail({
    this.name = null,
    this.username = null,
    this.email = null,
    this.organization = null,
    this.phone = null,
    this.pictureUrl = null,
    this.gender = null,
    this.birthYear = null,
    this.custom = null,
  });

  @override
  String toString() {
    return 'UserDetail{name: $name, username: $username, email: $email, organization: $organization, phone: $phone, pictureUrl: $pictureUrl, gender: $gender, birthYear: $birthYear, custom: $custom}';
  }

  @override
  Map<String, dynamic> toJson() => _$UserDetailToJson(this);

  factory UserDetail.fromJson(Map<String, dynamic> json) =>
      _$UserDetailFromJson(json);
}
