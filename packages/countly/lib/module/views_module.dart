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

class ViewsModule extends BaseEventModule {
  final Log = Logger('ViewsModule');

  bool _isFirstView = true;
  Map<String, int> _viewToLastViewStartTime = Map();

  ViewsModule({
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

  /// Start tracking a view. [name] of the view
  Future recordOpenView({required String name}) async {
    Log.info('recordOpenView : name = $name');

    if (!consents.checkConsentInternal(Consents.Views)) {
      return;
    }

    if (name.isEmpty) {
      Log.warning("recordCloseView : The view name '$name' isn't valid.");
      return;
    }

    if (name.length > configuration.maxKeyLength) {
      Log.shout(
          'recordOpenView : Max allowed key length is ${configuration.maxKeyLength}');
      name = name.substring(0, configuration.maxKeyLength);
    }

    _ViewSegment _viewSegment = _ViewSegment(
      name: name,
      visit: 1,
      segment: kIsWeb ? 'web' : Platform.operatingSystem,
      start: _isFirstView ? 1 : 0,
    );

    Event event = _buildEvent(
      key: BaseEventModule.ViewEvent,
      count: 1,
      sum: 0,
      duration: null,
      segmentation: _viewSegment.openViewSegments,
    );

    await recordEventInternal(event);

    if (!_viewToLastViewStartTime.containsKey("name")) {
      _viewToLastViewStartTime[name] = DateTime.now().millisecondsSinceEpoch;
    }

    _isFirstView = false;
  }

  /// Stop tracking a view.
  /// [name] of the view
  Future recordCloseView({required String name}) async {
    Log.info('recordCloseView : name = $name');

    if (!consents.checkConsentInternal(Consents.Views)) {
      return;
    }

    if (name.isEmpty) {
      Log.warning("recordCloseView : The view name '$name' isn't valid.");
      return;
    }

    if (name.length > configuration.maxKeyLength) {
      Log.shout(
          'recordCloseView : Max allowed key length is ${configuration.maxKeyLength}');
      name = name.substring(0, configuration.maxKeyLength);
    }

    _ViewSegment _viewSegment = _ViewSegment(
      name: name,
      visit: 0,
      segment: kIsWeb ? 'web' : Platform.operatingSystem,
      start: 0,
    );

    double? duration = null;
    if (_viewToLastViewStartTime.containsKey("name")) {
      int startTime = _viewToLastViewStartTime[name]!;
      duration = ((DateTime.now().millisecondsSinceEpoch - startTime) / 1000);

      _viewToLastViewStartTime.remove(name);
    }

    Event event = _buildEvent(
      key: BaseEventModule.ViewEvent,
      count: 1,
      sum: 0,
      duration: duration,
      segmentation: _viewSegment.closeViewSegments,
    );

    await recordEventInternal(event);

    _isFirstView = false;
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

  /// Reports a particular action with the specified details
  /// [type] type of action
  /// [x] x-coordinate
  /// [y] y-coordinate
  /// [width] width of screen
  /// [height] height of screen
  Future reportAction(String type, int x, int y, int width, int height) async {
    Log.info(
        'reportAction : type = $type, x = $x, y = $y, width = $width, height = $height');

    if (!consents.checkConsentInternal(Consents.Views)) {
      return;
    }

    var segments = <String, dynamic>{
      "type": Type,
      "x": x,
      "y": y,
      "width": width,
      "height": height,
    };

    Event event = _buildEvent(
      key: BaseEventModule.ViewActionEvent,
      count: 1,
      sum: 0,
      duration: null,
      segmentation: segments,
    );

    await recordEventInternal(event);
  }

  @override
  void onDeviceIdChanged(String? deviceId, bool merged) {
    if (!merged) {
      _isFirstView = true;
    }
  }
}

class _ViewSegment {
  final String name;
  final String segment;
  final int visit;
  final int start;

  _ViewSegment({
    required this.name,
    required this.segment,
    required this.visit,
    required this.start,
  });

  get openViewSegments => <String, dynamic>{
        'name': name,
        'visit': visit,
        'start': start,
        'segment': segment,
      };

  get closeViewSegments => <String, dynamic>{
        'name': name,
        'segment': segment,
      };
}
