import 'dart:convert';

import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/user_detail.dart';
import 'package:logging/logging.dart';

import 'base_module.dart';

class UserDetailModule extends BaseModule {
  final Log = Logger('UserDetailModule');
  Map<String, dynamic> _customProperties = {};

  String? _deviceId;
  final RequestsController _requestController;

  String? get deviceId => _deviceId;

  UserDetailModule({
    required TimeHelper timeHelper,
    required Configuration configuration,
    required ConsentController consents,
    required RequestsController requestController,
  })  : this._requestController = requestController,
        super(
            configuration: configuration,
            timeHelper: timeHelper,
            consents: consents) {
    Log.info("Initializing.");
  }

  @override
  void onConsentChanged(List<String> updatedConsents, bool newConsentValue) {
    if (updatedConsents.contains(Consents.RemoteConfig) && !newConsentValue) {}
  }

  /// Sets information about user.
  /// [userDetails] User detail model with the specified fields
  Future setUserDetails(UserDetail userDetails) async {
    Log.info('setUserDetailsAsync: userDetails = ${userDetails.toString()}');

    if (!consents.checkConsentInternal(Consents.Users)) {
      return;
    }

    //
    // if (!_countlyUtils.IsPictureValid(userDetails.PictureUrl)) {
    //   throw new Exception("Accepted picture formats are .png, .gif and .jpeg");
    // }

    userDetails.name = trimValue("name", userDetails.name);
    userDetails.phone = trimValue("phone", userDetails.phone);
    userDetails.email = trimValue("email", userDetails.email);
    userDetails.gender = trimValue("gender", userDetails.gender);
    userDetails.username = trimValue("username", userDetails.username);
    userDetails.birthYear = trimValue("birthYear", userDetails.birthYear);
    userDetails.organization =
        trimValue("organization", userDetails.organization);

    if (userDetails.pictureUrl != null &&
        userDetails.pictureUrl!.length > 4096) {
      Log.warning("trimValue: Max allowed length of 'pictureUrl' is 4096");
      userDetails.pictureUrl = userDetails.pictureUrl!.substring(0, 4096);
    }

    userDetails.custom = fixSegmentKeysAndValues(userDetails.custom);
    Map<String, dynamic> requestParams = <String, dynamic>{
      'user_details': jsonEncode(userDetails.toJson())
    };

    await _requestController.addToRequestQueue(requestParams);
  }

  /// Sets information about user with custom properties.
  /// In custom properties you can provide any String key values to be stored with user.
  Future userCustomDetail(Map<String, dynamic> customProperties) async {
    Log.info("UserCustomProperties: customProperties = ${customProperties}");
    if (!consents.checkConsentInternal(Consents.Users)) {
      return;
    }

    if (customProperties.isEmpty) {
      Log.warning(
          "UserCustomProperties: The custom property 'customProperties' empty.");
      return;
    }

    await _addCustomDetailToRequestQueue(customProperties);
  }

  /// Send provided values to server.
  Future save() async {
    if (!_customProperties.isEmpty) {
      return;
    }

    Log.info("saveAsync");

    await _addCustomDetailToRequestQueue(_customProperties);
    _customProperties.clear();
  }

  /// Sets custom provide key/value as custom property.

  /// [key] String with key for the property
  /// [value] String with value for the property
  void set(String key, String value) {
    if (key.isEmpty) {
      Log.warning("set: key '$key' isn't valid.");

      return;
    }

    Log.info(
        "[UserDetailsCountlyService] set: key = " + key + ", value = " + value);

    _addToCustomData(key, trimValue(key, value));
  }

  /// Set value only if property does not exist yet.
  /// [key] String with key for the property
  /// [value] String with value for the property
  void setOnce(String key, String value) {
    if (key.isEmpty) {
      Log.warning("set: key '$key' isn't valid.");

      return;
    }

    Log.info("[UserDetailsCountlyService] setOnce: key = " +
        key +
        ", value = " +
        value);

    _addToCustomData(key, {"\$setOnce", trimValue(key, value)});
  }

  /// Increment custom property value by 1.
  /// [key] String with property name to increment
  void increment(String key) {
    if (key.isEmpty) {
      Log.warning("increment: key $key isn't valid.");

      return;
    }

    Log.info("increment: key = " + key);

    _addToCustomData(key, jsonEncode({"\$inc", 1}));
  }

  /// Increment custom property value by provided value.
  /// [key] String with property name to increment
  /// [value] double value by which to increment
  void incrementBy(String key, double value) {
    if (key.isEmpty) {
      Log.warning("incrementBy: key $key isn't valid.");

      return;
    }
    Log.info(
        "[UserDetailsCountlyService] IncrementBy: key = $key , value = $value");

    _addToCustomData(key, {"\$inc", value});
  }

  /// Multiply custom property value by provided value.
  /// [key] String with property name to multiply
  /// [value] double value by which to multiply
  void multiply(String key, double value) {
    if (key.isEmpty) {
      Log.warning(
          "[UserDetailsCountlyService] Multiply: key '$key isn't valid.");

      return;
    }

    Log.info(
        "[UserDetailsCountlyService] Multiply: key = $key , value = $value");

    _addToCustomData(key, {"\$mul", value});
  }

  /// Save maximal value between existing and provided.
  /// [key] String with property name to check for max
  /// [value] double value to check for max
  void max(String key, double value) {
    if (key.isEmpty) {
      Log.warning("[UserDetailsCountlyService] Max: key $key isn't valid.");

      return;
    }

    Log.info(
        "[UserDetailsCountlyService] Max: key = " + key + ", value = $value");

    _addToCustomData(key, {"\$max", value});
  }

  /// Save minimal value between existing and provided.
  /// [key] String with property name to check for min
  /// [value] double value to check for min
  void Min(String key, double value) {
    if (key.isEmpty) {
      Log.warning("[UserDetailsCountlyService] Min: key $key isn't valid.");

      return;
    }

    Log.info("[UserDetailsCountlyService] Min: key = $key , value = $value");

    _addToCustomData(key, {"\$min", value});
  }

  /// Create array property, if property does not exist and add value to array
  /// You can only use it on array properties or properties that do not exist yet.
  /// [key] String with property name for array property
  /// [value] array with values to add
  void push(String key, List<String> value) {
    if (key.isEmpty) {
      Log.warning("[UserDetailsCountlyService] Push: key = $key isn't valid.");

      return;
    }

    Log.info("[UserDetailsCountlyService] Push: key = $key , value = $value");

    _addToCustomData(key, {"\$push", jsonEncode(trimValues(value))});
  }

  /// Create array property, if property does not exist and add value to array, only if value is not yet in the array
  /// You can only use it on array properties or properties that do not exist yet.

  /// [key] String with property name for array property
  /// [value] array with values to add
  void pushUnique(String key, List<String> value) {
    if (key.isEmpty) {
      Log.warning(
          "[UserDetailsCountlyService] PushUnique: key = $key isn't valid.");

      return;
    }

    Log.info(
        "[UserDetailsCountlyService] PushUnique: key = $key , value = $value");
    _addToCustomData(key, {"\$addToSet", jsonEncode(trimValues(value))});
  }

  /// Create array property, if property does not exist and remove value from array.

  /// [key] String with property name for array property
  /// [value] array with values to remove from array
  void pull(String key, List<String> value) {
    if (key.isEmpty) {
      Log.warning("[UserDetailsCountlyService] Pull: key = $key isn't valid.");

      return;
    }

    Log.info("[UserDetailsCountlyService] Pull: key = $key , value = $value");

    value = trimValues(value);
    _addToCustomData(key, {"\$pull", jsonEncode(trimValues(value))});
  }

  /// Create a property
  /// [key] property name
  /// [value] property value
  void _addToCustomData(String key, dynamic value) {
    Log.fine("addToCustomData: " + key + ", " + value);

    if (!consents.checkConsentInternal(Consents.Users)) {
      return;
    }

    key = trimKey(key);

    // if (_customProperties.containsKey(key)) {
    //   //     String item = CustomDataProperties.Select(x => x.Key).FirstOrDefault(x => x.Equals(key, StringComparison.OrdinalIgnoreCase));
    //   // if (item != null) {
    //   // _customProperties.remove(item);
    // }

    _customProperties[key] = value;
  }

  /// Add user custom detail to request queue.
  Future _addCustomDetailToRequestQueue(
      Map<String, dynamic> customProperties) async {
    Map<String, dynamic>? customDetail =
        fixSegmentKeysAndValues(customProperties);

    Map<String, dynamic> requestParams = {
      'user_details': jsonEncode({"custom", jsonEncode(customDetail)})
    };

    await _requestController.addToRequestQueue(requestParams);
  }
}
