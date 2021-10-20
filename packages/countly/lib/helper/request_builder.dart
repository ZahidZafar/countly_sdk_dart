import 'dart:convert';

import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/TimeMetrics.dart';
import 'package:countly/model/configuration.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

class RequestBuilder {
  final log = Logger('RequestBuilder');
  final Configuration _configuration;
  final TimeHelper _timeHelper;
  RequestBuilder(
      {required Configuration configuration, required TimeHelper timeHelper})
      : _configuration = configuration,
        _timeHelper = timeHelper;

  Map<String, dynamic> baseParams() {
    int timestamp = _timeHelper.getUniqueTimestamp();
    TimeMetrics timeMetrics = TimeMetrics(timestamp: timestamp);

    Map<String, dynamic> baseParams = <String, dynamic>{
      "app_key": _configuration.appKey,
      "sdk_name": _configuration.sdkName,
      "device_id": _configuration.deviceId,
      "sdk_version": _configuration.sdkVersion,
      //Time metrics
      'hour': timeMetrics.hour,
      'dow': timeMetrics.dow,
      'tz': timeMetrics.tz,
      'timestamp': timeMetrics.timestamp,
    };

    return baseParams;
  }

  String buildRequest(Map<String, dynamic> params) {
    log.fine('buildGetRequest: params = ${params.toString()}');
    Map<String, dynamic> body = baseParams();
    body.addAll(params);

    print(body.toString());
    String uri = body.keys
        .map((key) =>
            "${Uri.encodeComponent(key)}=${Uri.encodeComponent(body[key].toString())}")
        .join("&");

    if (![null, '', ' '].contains(_configuration.salt)) {
      List<int> bytes = utf8.encode(uri + _configuration.salt!);

      var digest = sha256.convert(bytes);
      uri += '&checksum256=' + digest.toString();
    }

    log.fine('buildGetRequest: query = $uri');
    return uri;
  }
}
