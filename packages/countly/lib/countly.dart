library countly;

import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/request_builder.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/module/crash_module.dart';
import 'package:countly/module/device_module.dart';
import 'package:countly/module/events_module.dart';
import 'package:countly/module/location_module.dart';
import 'package:countly/module/remote_config_module.dart';
import 'package:countly/module/sessions_module.dart';
import 'package:countly/module/star_rating_module.dart';
import 'package:countly/module/user_profile_module.dart';
import 'package:countly/repository/config_repository.dart';
import 'package:countly/repository/event_repository.dart';
import 'package:countly/repository/request_repository.dart';
import 'package:logging/logging.dart';
import 'package:sembast_web/sembast_web.dart';

import 'module/views_module.dart';

class Countly {
  late final _db;
  final log = Logger('EventsModule');
  late final EventsModule _eventsModule;
  late final ViewsModule _viewsModule;
  late final ConsentController _consentModule;
  late final RequestsController _requestsController;
  late final SessionsModule _sessionsModule;
  late final LocationModule _locationModule;
  late final StarRatingModule _starRating;
  late final UserDetailModule _userDetail;
  late final RemoteConfigModule _remoteConfigModule;
  late final DeviceModule _deviceModule;
  late final CrashModule _crashModule;

  CrashModule get crash => _crashModule;
  ViewsModule get views => _viewsModule;
  DeviceModule get device => _deviceModule;
  UserDetailModule get user => _userDetail;
  EventsModule get events => _eventsModule;

  StarRatingModule get starRating => _starRating;
  LocationModule get location => _locationModule;
  SessionsModule get sessions => _sessionsModule;
  ConsentController get consents => _consentModule;

  RemoteConfigModule get remoteConfig => _remoteConfigModule;

  Countly._(this._configuration);
  late final Configuration _configuration;

  static Future<Countly> init({required Configuration configuration}) async {
    Countly instance = Countly._(configuration);
    instance.log.config('init: configuration = ${configuration.toString()}');

    if (configuration.enableConsoleLogging) {
      Logger.root.level = Level.ALL;
    } else {
      Logger.root.level = Level.OFF;
    }
    Logger.root.onRecord.listen((record) {
      print(
          '${record.time} ===> : [${record.level.name}]: [${record.loggerName}]: ${record.message}');
    });

    await instance._initializeModules();
    return instance;
  }

  Future<void> _initializeModules() async {
    var dbFactory = databaseFactoryWeb;
    //   var dbFactory = databaseFactoryIo; //databaseFactoryWeb;

    //final appDocumentDir = await getApplicationDocumentsDirectory();

    //  final dbPath = join(appDocumentDir.path, 'countly.db');
    final dbPath = 'countly.db';
    _db = await dbFactory.openDatabase(dbPath);

    TimeHelper timeHelper = TimeHelper();
    RequestBuilder requestBuilder =
        RequestBuilder(configuration: _configuration, timeHelper: timeHelper);
    EventRepository eventRepository = EventRepository(db: _db);
    RequestRepository requestRepository = RequestRepository(db: _db);

    _requestsController = RequestsController(
      requestBuilder: requestBuilder,
      configuration: _configuration,
      requestRepository: requestRepository,
    );

    _consentModule = ConsentController(
      eventRepository: eventRepository,
      configuration: _configuration,
      requestsModule: _requestsController,
    );

    _viewsModule = ViewsModule(
      timeHelper: timeHelper,
      consentModule: _consentModule,
      configuration: _configuration,
      eventRepository: eventRepository,
      requestsModule: _requestsController,
    );

    _eventsModule = EventsModule(
      timeHelper: timeHelper,
      consentModule: _consentModule,
      configuration: _configuration,
      eventRepository: eventRepository,
      requestsModule: _requestsController,
    );

    _locationModule = LocationModule(
        timeHelper: timeHelper,
        configuration: _configuration,
        requestsModule: _requestsController,
        consents: consents);

    _sessionsModule = SessionsModule(
      timeHelper: timeHelper,
      eventsModule: _eventsModule,
      consents: _consentModule,
      locationModule: _locationModule,
      configuration: _configuration,
      requestsModule: _requestsController,
    );

    _starRating = StarRatingModule(
        timeHelper: timeHelper,
        configuration: _configuration,
        requestsModule: _requestsController,
        eventRepository: eventRepository,
        consentModule: _consentModule);

    _userDetail = UserDetailModule(
      timeHelper: timeHelper,
      configuration: _configuration,
      consents: _consentModule,
      requestController: _requestsController,
    );

    RemoteConfigRepository remoteConfigRepository =
        RemoteConfigRepository(db: _db);
    _remoteConfigModule = RemoteConfigModule(
      timeHelper: timeHelper,
      configuration: _configuration,
      consents: _consentModule,
      requestBuilder: requestBuilder,
      remoteConfigRepository: remoteConfigRepository,
    );

    _deviceModule = DeviceModule(
      timeHelper: timeHelper,
      configuration: _configuration,
      requestsModule: _requestsController,
      consents: _consentModule,
      locationModule: _locationModule,
      eventsModule: _eventsModule,
      sessionsModule: _sessionsModule,
    );

    _crashModule = CrashModule(
      timeHelper: timeHelper,
      consents: _consentModule,
      configuration: _configuration,
      requestsModule: _requestsController,
    );

    await _onInitializationComplete();
  }

  _onInitializationComplete() async {
    await _consentModule.onInitializationCompleted();
    await _sessionsModule.onInitializationCompleted();
  }
}
