import 'dart:collection';
import 'dart:convert';

import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/device_metrics.dart';
import 'package:logging/logging.dart';

import 'base_module.dart';

class CrashModule extends BaseModule {
  final Log = Logger('CrashModule');

  final RequestsController _requestsModule;
  final Queue<String> _breadcrumbs = new Queue();

  CrashModule({
    required TimeHelper timeHelper,
    required ConsentController consents,
    required Configuration configuration,
    required RequestsController requestsModule,
  })  : this._requestsModule = requestsModule,
        super(
            configuration: configuration,
            timeHelper: timeHelper,
            consents: consents) {
    Log.info("Initializing.");

    if (configuration.isAutomaticSessionTrackingDisabled) {
      Log.fine("Automatic session tracking disabled!");
    }
  }

  /// Public method that sends crash details to the server. Set param "nonfatal" to true for Custom Logged errors
  /// [message] a string that contain detailed description of the exception.
  /// [stackTrace] a string that describes the contents of the callstack.
  /// [segments] custom key/values to be reported
  /// [nonfatal]
  Future sendCrashReport({
    required String message,
    required String? stackTrace,
    Map<String, dynamic>? segments = null,
    bool nonfatal = true,
  }) async {
    Log.info(
        'sendCrashReportAsync : message =  $message, $stackTrace = $stackTrace');

    if (!consents.checkConsentInternal(Consents.Crashes)) {
      return;
    }

    List<String?> nullEmpty = ['', null, ' '];
    if (nullEmpty.contains(message)) {
      Log.warning(
          "sendCrashReportAsync : The parameter 'message' can't be null or empty");
      return;
    }

    sendCrashReportInternal(
      message: message,
      segments: segments,
      stackTrace: stackTrace,
      nonfatal: nonfatal,
    );
  }

  Future sendCrashReportInternal({
    required String message,
    String? stackTrace = null,
    Map<String, dynamic>? segments = null,
    bool nonfatal = true,
  }) async {
    Log.fine("sendCrashReportInternal : model = ");
    Map<String, dynamic> crash = {
      '_name': message,
      '_error': stackTrace,
      '_custom': removeSegmentInvalidDataTypes(segments),
      '_nonfatal': nonfatal,
      '_logs': _breadcrumbs.map((e) => e).join('\n'),
    };

    DeviceMetrics crashMetrics = await DeviceMetrics.build();

    crash.addAll(crashMetrics.metricsToJson());

    Map<String, dynamic> requestParams = <String, dynamic>{
      'crash': jsonEncode(crash),
    };

    await _requestsModule.addToRequestQueue(requestParams);
  }

  /// Adds string value to a list which is later sent over as logs whenever a cash is reported by system.
  /// [value] a bread crumb for the crash report
  void addBreadcrumbs(String value) {
    Log.info("addBreadcrumbs : $value");

    if (!consents.checkConsentInternal(Consents.Crashes)) {
      return;
    }

    if (configuration.enableTestMode) {
      return;
    }

    String validBreadcrumb = value.length > configuration.maxValueSize
        ? value.substring(0, configuration.maxValueSize)
        : value;

    if (_breadcrumbs.length == configuration.totalBreadcrumbsAllowed) {
      _breadcrumbs.removeFirst();
    }

    _breadcrumbs.add(validBreadcrumb);
  }
}
