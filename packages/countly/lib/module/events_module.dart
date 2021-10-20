import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/TimeMetrics.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/event.dart';
import 'package:countly/module/base_event_module.dart';
import 'package:countly/repository/event_repository.dart';
import 'package:logging/logging.dart';

class EventsModule extends BaseEventModule {
  final Log = Logger('EventsModule');

  EventsModule({
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

  Future<void> recordEvent({
    required String key,
    int count = 0,
    double sum = 1,
    double? duration = null,
    Map<String, dynamic>? segmentation,
  }) async {
    if (key.isEmpty) {
      Log.shout("recordEvent: key = '$key' can't be empty.");
    }

    Log.info("recordEvent: key = " + key);
    Event event = _buildEvent(
        key: key,
        count: count,
        sum: sum,
        duration: duration,
        segmentation: segmentation);

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
        segmentation: removeSegmentInvalidDataTypes(segmentation),
        dow: timeMetrics.dow,
        hour: timeMetrics.hour,
        timestamp: timestamp);

    return event;
  }
}
