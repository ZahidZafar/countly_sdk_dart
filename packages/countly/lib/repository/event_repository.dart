import 'dart:collection';

import 'package:countly/model/event.dart';
import 'package:sembast/sembast.dart';

import 'base_repository.dart';

class EventRepository extends Repository<Event> {
  EventRepository({required Database db}) : super(db: db, storeName: "events");

  Future<Queue> getEventQueue() async {
    List<Event> events = await findAll();
    print(events.toString());

    Queue _eventQ = new Queue();
    _eventQ.addAll(events);
    return _eventQ;
  }
}
