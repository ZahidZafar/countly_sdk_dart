import 'dart:collection';

import 'package:countly/model/request.dart';
import 'package:sembast/sembast.dart';

import 'base_repository.dart';

class RequestRepository extends Repository<Request> {
  RequestRepository({required Database db})
      : super(db: db, storeName: "requests");

  Future<Queue> getRequestQueue() async {
    List<Request> events = await findAll();
    Queue _eventQ = new Queue();
    _eventQ.addAll(events);
    return _eventQ;
  }
}
