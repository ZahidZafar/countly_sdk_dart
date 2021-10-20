import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/module/events_module.dart';
import 'package:countly/module/sessions_module.dart';
import 'package:logging/logging.dart';

import 'base_module.dart';
import 'location_module.dart';

class DeviceModule extends BaseModule {
  final Log = Logger('SessionsModule');

  String? _deviceId;
  final EventsModule _eventsModule;
  final SessionsModule _sessionsModule;
  final RequestsController _requestsModule;

  String? get deviceId => _deviceId;

  DeviceModule({
    required TimeHelper timeHelper,
    required Configuration configuration,
    required RequestsController requestsModule,
    required ConsentController consents,
    required LocationModule locationModule,
    required EventsModule eventsModule,
    required SessionsModule sessionsModule,
  })  : this._eventsModule = eventsModule,
        this._requestsModule = requestsModule,
        this._sessionsModule = sessionsModule,
        super(
            configuration: configuration,
            timeHelper: timeHelper,
            consents: consents) {
    Log.info("Initializing.");

    if (configuration.isAutomaticSessionTrackingDisabled) {
      Log.fine("Automatic session tracking disabled!");
    }
  }

  void initDeviceId({required final String? deviceId}) {
    //TODO generate unique device id
    String? storeDeviceId =
        null; //PlayerPrefs.GetString(Constants.DeviceIDKey);
    var emptyAndNull = ['', null];
    if (!emptyAndNull.contains(storeDeviceId)) {
      _deviceId = storeDeviceId;
    } else if (!emptyAndNull.contains(deviceId)) {
      _deviceId = deviceId;
    } else {
      //TODO generate unique device id
      _deviceId = 'generated device id';
    }
  }

  /// Changes Device Id.
  /// Adds currently recorded but not queued events to request queue.
  /// Clears all started timed-events
  /// Ends current session with old Device Id.
  /// Begins a new session with new Device Id
  /// [newDeviceId] new device id
  Future changeDeviceIdWithoutMerge({required String newDeviceId}) async {
    Log.info("changeDeviceIdWithoutMerge: newDeviceId = $newDeviceId");

    if (!consents.anyConsentGiven()) {
      Log.shout(
          "[DeviceIdCountlyService] ChangeDeviceIdWithoutMerge: Please set at least a single consent before calling this!");
      return;
    }

    if (deviceId == newDeviceId) {
      return;
    }

    //Add currently recorded events to request queue
    await _eventsModule.addEventsToRequestQueue();

    //Do not dispose timer object
    if (!configuration.isAutomaticSessionTrackingDisabled) {
      await _sessionsModule.endSession();
    }

    _updateDeviceId(newDeviceId);

    if (!configuration.isAutomaticSessionTrackingDisabled) {
      await _sessionsModule.beginSession();
    }

    await _requestsModule.processRequestQueue();

    _notifyListeners(merged: false);
  }

  Future changeDeviceIdWithMerge({required String newDeviceId}) async {
    Log.info("changeDeviceIdWithMerge: newDeviceId = $newDeviceId");

    if (!consents.anyConsentGiven()) {
      Log.shout(
          "changeDeviceIdWithMerge: Please set at least a single consent before calling this!");
      return;
    }

    if (deviceId == newDeviceId) {
      return;
    }

    String? oldDeviceId = deviceId;
    _updateDeviceId(newDeviceId);

    Map<String, dynamic> requestParams = <String, dynamic>{
      "old_device_id": oldDeviceId,
    };

    await _requestsModule.addToRequestQueue(requestParams);
    await _requestsModule.processRequestQueue();
    _notifyListeners(merged: true);
  }

  /// Updates Device ID both in app and in cache
  /// [newDeviceId] new device id
  _updateDeviceId(String newDeviceId) {
    //Change device id
    _deviceId = newDeviceId;

    //Updating Cache TODO
    //  PlayerPrefs.SetString(Constants.DeviceIDKey, DeviceId);

    Log.info("_updateDeviceId: newDeviceId = $newDeviceId");
  }

  /// Call [onDeviceIdChanged] on all listeners.
  /// [merged]If passed "true" if will perform a device ID merge serverside of the old and new device ID. This will merge their data
  _notifyListeners({required bool merged}) {
    if (listeners.isEmpty) {
      return;
    }

    for (BaseModule listener in listeners) {
      listener.onDeviceIdChanged(deviceId, merged);
    }
  }
}
