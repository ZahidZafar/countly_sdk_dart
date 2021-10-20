import 'dart:io' show Platform;

import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/TimeMetrics.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/event.dart';
import 'package:countly/module/base_event_module.dart';
import 'package:countly/repository/event_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';

class StarRatingModule extends BaseEventModule {
  final Log = Logger('StarRatingModule');

  StarRatingModule({
    required Configuration configuration,
    required TimeHelper timeHelper,
    required RequestsController requestsModule,
    required ConsentController consentModule,
    required EventRepository eventRepository,
  }) : super(
            timeHelper: timeHelper,
            configuration: configuration,
            consents: consentModule,
            eventRepository: eventRepository,
            requestsModule: requestsModule) {
    Log.fine("Initialized");
  }

  /// Sends app rating to the server.
  /// [platform] name of platform</param>
  /// [appVersion] the current version of the app</param>
  /// [rating] value from 1 to 5 that will be set as the rating value</param>
  Future reportStarRating(
      {required String platform,
      required String appVersion,
      required int rating}) async {
    Log.info(
        'reportRating : platform = $platform, appVersion = $appVersion, rating = $rating');

    if (!consents.checkConsentInternal(Consents.StarRating)) {
      return;
    }

    if (platform.isEmpty) {
      Log.warning(
          "reportStarRating : The platform name '$platform' isn't valid.");
      return;
    }

    if (appVersion.isEmpty) {
      Log.warning(
          "reportStarRating : The appVersion '$appVersion' isn't valid.");
      return;
    }

    if (rating < 1 || rating > 5) {
      Log.warning("reportStarRating : The rating value '$rating' isn't valid.");
      return;
    }

    var segments = <String, dynamic>{
      "platform": kIsWeb ? 'web' : Platform.operatingSystem,
      "app_version": appVersion,
      "rating": rating,
    };

    Event event = _buildEvent(
      key: BaseEventModule.StarRatingEvent,
      count: 1,
      sum: 0,
      duration: null,
      segmentation: segments,
    );

    await recordEventInternal(event);
  }

  Event _buildEvent({
    required String key,
    required int count,
    required double sum,
    required double? duration,
    required Map<String, dynamic>? segmentation,
  }) {
    int timestamp = timeHelper.getUniqueTimestamp();
    TimeMetrics timeMetrics = TimeMetrics(timestamp: timestamp);
    Event event = Event(
        key: key,
        count: count,
        sum: sum,
        duration: duration,
        segmentation: segmentation,
        dow: timeMetrics.dow,
        hour: timeMetrics.hour,
        timestamp: timestamp);

    return event;
  }
}
