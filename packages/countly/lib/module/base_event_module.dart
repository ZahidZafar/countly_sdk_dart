import 'dart:collection';
import 'dart:convert';

import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/event.dart';
import 'package:countly/repository/event_repository.dart';
import 'package:logging/logging.dart';

import 'base_module.dart';

class BaseEventModule extends BaseModule {
  final Log = Logger('BaseEventModule');

  bool _addingEventsToRequestQueue = false;
  final RequestsController _requestsModule;
  final EventRepository _eventRepository;

  static const String NPSEvent = "[CLY]_nps";
  static const String ViewEvent = "[CLY]_view";
  static const String SurveyEvent = "[CLY]_survey";
  static const String ViewActionEvent = "[CLY]_action";
  static const String StarRatingEvent = "[CLY]_star_rating";
  static const String PushActionEvent = "[CLY]_push_action";
  static const String OrientationEvent = "[CLY]_orientation";

  BaseEventModule({
    required EventRepository eventRepository,
    required TimeHelper timeHelper,
    required Configuration configuration,
    required RequestsController requestsModule,
    required ConsentController consents,
  })  : this._eventRepository = eventRepository,
        this._requestsModule = requestsModule,
        super(
            configuration: configuration,
            timeHelper: timeHelper,
            consents: consents);

  Future<void> recordEventInternal(Event event) async {
    Log.fine("recordEvent: event = " + event.toString());

    await _eventRepository.insert(event);

    Queue q = await _eventRepository.getEventQueue();
    if (q.length >= configuration.eventQueueThreshold) {
      await addEventsToRequestQueue();
    }
  }

  Future<void> addEventsToRequestQueue() async {
    Log.fine(
        'addEventsToRequestQueue: addingEventsToRequestQueue = $_addingEventsToRequestQueue');
    if (_addingEventsToRequestQueue) {
      return;
    }
    _addingEventsToRequestQueue = true;
    Queue q = await _eventRepository.getEventQueue();
    Log.fine('addEventsToRequestQueue: count = ${q.length}');
    List<int?> keys = [];

    String events = jsonEncode(q.toList());

    Map<String, dynamic> eventsParams = <String, dynamic>{
      "events": events,
    };

    await _requestsModule.addToRequestQueue(eventsParams);

    for (Event e in q) {
      keys.add(e.id);
    }

    await _eventRepository.removeAllIn(keys);
    _addingEventsToRequestQueue = false;
  }
}
