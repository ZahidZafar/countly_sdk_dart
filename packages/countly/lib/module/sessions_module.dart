import 'dart:async';
import 'dart:convert';

import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/device_metrics.dart';
import 'package:countly/module/events_module.dart';
import 'package:logging/logging.dart';

import 'base_module.dart';
import 'location_module.dart';

class SessionsModule extends BaseModule {
  final Log = Logger('SessionsModule');

  bool _isSessionInitiated = false;

  final EventsModule _eventsModule;
  final LocationModule _locationModule;
  final RequestsController _requestsModule;

  DateTime _lastSessionRequestTime = DateTime.now();

  bool get isSessionInitiated => _isSessionInitiated;

  SessionsModule({
    required TimeHelper timeHelper,
    required Configuration configuration,
    required RequestsController requestsModule,
    required ConsentController consents,
    required LocationModule locationModule,
    required EventsModule eventsModule,
  })  : this._eventsModule = eventsModule,
        this._requestsModule = requestsModule,
        this._locationModule = locationModule,
        super(
            configuration: configuration,
            timeHelper: timeHelper,
            consents: consents) {
    Log.info("Initializing.");

    if (configuration.isAutomaticSessionTrackingDisabled) {
      Log.fine("Automatic session tracking disabled!");
    }
  }
  @override
  Future onInitializationCompleted() async {
    _startSession();
  }

  /// Run session startup logic and start timer with the specified interval
  Future _startSession() async {
    Log.info("_startSession");
    if (configuration.isAutomaticSessionTrackingDisabled ||
        !consents.checkConsentInternal(Consents.Sessions)) {
      /* If location is disabled in init
                and no session consent is given. Send empty location as separate request.*/
      if (_locationModule.isLocationDisabled ||
          !consents.checkConsentInternal(Consents.Location)) {
        await _locationModule.sendRequestWithEmptyLocation();
      } else {
        /*
         * If there is no session consent or automatic session tracking is disabled,
         * location values set in init should be sent as a separate location request.
         */
        await _locationModule.sendIndependentLocationRequest();
      }
    } else {
      //Start Session
      await beginSession();
    }

    _startTimer();
  }

  _startTimer() {
    Log.info("_startTimer");
    Timer.periodic(Duration(seconds: configuration.sessionDuration), (timer) {
      Log.info("_startTimer: TimerOnElapsed");
      _eventsModule.addEventsToRequestQueue();
      if (!configuration.isAutomaticSessionTrackingDisabled) {
        extendSession();
      }
    });
  }

  /// Initiates a session
  Future beginSession() async {
    Log.info("beginSession");

    if (!consents.checkConsentInternal(Consents.Sessions)) {
      return;
    }

    if (isSessionInitiated) {
      Log.warning("beginSession: The session has already started!");
      return;
    }

    _lastSessionRequestTime = DateTime.now();
    //Session initiated
    _isSessionInitiated = true;

    Map<String, dynamic> requestParams = Map();

    requestParams["begin_session"] = 1;

    /* If location is disabled or no location consent is given,
            the SDK adds an empty location entry to every "begin_session" request. */
    if (_locationModule.isLocationDisabled ||
        !consents.checkConsentInternal(Consents.Location)) {
      requestParams["location"] = "";
    } else {
      if (_locationModule.ipAddress != null &&
          _locationModule.ipAddress!.isNotEmpty) {
        requestParams["ip_address"] = _locationModule.ipAddress;
      }

      if (_locationModule.countryCode != null &&
          _locationModule.countryCode!.isNotEmpty) {
        requestParams["country_code"] = _locationModule.countryCode;
      }

      if (_locationModule.city != null && _locationModule.city!.isNotEmpty) {
        requestParams["city"] = _locationModule.city;
      }

      if (_locationModule.location != null &&
          _locationModule.location!.isNotEmpty) {
        requestParams["location"] = _locationModule.location;
      }
    }

    DeviceMetrics metrics = await DeviceMetrics.build();
    requestParams['metrics'] = jsonEncode(metrics.metricsToJson());

    await _requestsModule.addToRequestQueue(requestParams);
  }

  Future endSession() async {
    Log.info("endSession");

    if (!consents.checkConsentInternal(Consents.Sessions)) {
      return;
    }

    if (!isSessionInitiated) {
      Log.warning("endSession: The session isn't started yet!");
      return;
    }

    _isSessionInitiated = false;

    _eventsModule.addEventsToRequestQueue();

    Map<String, dynamic> requestParams = <String, dynamic>{
      "end_session": 1,
      "session_duration": ((DateTime.now().millisecondsSinceEpoch -
                  _lastSessionRequestTime.millisecondsSinceEpoch) /
              1000)
          .floor()
    };

    await _requestsModule.addToRequestQueue(requestParams);
  }

  /// Extends a session by another session duration provided in configuration. By default session duration is 60 seconds.
  Future extendSession() async {
    Log.info("extendSession");

    if (!consents.checkConsentInternal(Consents.Sessions)) {
      return;
    }

    if (!isSessionInitiated) {
      Log.warning("extendSession: The session isn't started yet!");
      return;
    }

    Map<String, dynamic> requestParams = <String, dynamic>{
      "session_duration": ((DateTime.now().millisecondsSinceEpoch -
                  _lastSessionRequestTime.millisecondsSinceEpoch) /
              1000)
          .floor()
    };

    _lastSessionRequestTime = DateTime.now();

    await _requestsModule.addToRequestQueue(requestParams);
  }

  @override
  void onConsentChanged(
      List<String> updatedConsents, bool newConsentValue) async {
    if (updatedConsents.contains(Consents.Sessions) && newConsentValue) {
      if (!configuration.isAutomaticSessionTrackingDisabled) {
        _isSessionInitiated = false;
        await beginSession();
      }
    }
  }
}
