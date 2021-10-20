// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDetail _$UserDetailFromJson(Map<String, dynamic> json) => UserDetail(
      name: json['name'] as String? ?? null,
      username: json['username'] as String? ?? null,
      email: json['email'] as String? ?? null,
      organization: json['organization'] as String? ?? null,
      phone: json['phone'] as String? ?? null,
      pictureUrl: json['picture'] as String? ?? null,
      gender: json['gender'] as String? ?? null,
      birthYear: json['byear'] as String? ?? null,
      custom: json['custom'] as Map<String, dynamic>? ?? null,
    )..id = json['id'] as int?;

Map<String, dynamic> _$UserDetailToJson(UserDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'email': instance.email,
      'organization': instance.organization,
      'phone': instance.phone,
      'picture': instance.pictureUrl,
      'gender': instance.gender,
      'byear': instance.birthYear,
      'custom': instance.custom,
    };
