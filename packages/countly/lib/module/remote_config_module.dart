import 'dart:convert';

import 'package:countly/controller/consent_controller.dart';
import 'package:countly/helper/request_builder.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/Response.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/device_metrics.dart';
import 'package:countly/model/remote_config.dart';
import 'package:countly/repository/config_repository.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'base_module.dart';

class RemoteConfigModule extends BaseModule {
  final Log = Logger('RemoteConfigModule');

  String? _deviceId;
  final RemoteConfigRepository _remoteConfigRepository;
  final RequestBuilder _requestBuilder;

  Map<String, dynamic> _configs = {};
  Map<String, dynamic> get configs => _configs;

  String? get deviceId => _deviceId;

  RemoteConfigModule({
    required TimeHelper timeHelper,
    required Configuration configuration,
    required ConsentController consents,
    required RequestBuilder requestBuilder,
    required RemoteConfigRepository remoteConfigRepository,
  })  : this._remoteConfigRepository = remoteConfigRepository,
        this._requestBuilder = requestBuilder,
        super(
            configuration: configuration,
            timeHelper: timeHelper,
            consents: consents) {
    Log.info("Initializing.");
    _loadLocalConfig();
  }

  ///     Fetch locally stored remote config values.
  _loadLocalConfig() async {
    if (consents.checkConsentInternal(Consents.RemoteConfig)) {
      List<RemoteConfig> configs = await _remoteConfigRepository.findAll();
      if (configs.isNotEmpty) {
        _configs = json.decode(configs[0].data);
      }
    } else {
      _remoteConfigRepository.removeAll();
    }
  }

  Future<Response> _httpGet(String query) async {
    Log.fine("httpGet: query = $query");

    var url = Uri.parse(configuration.serverUrl + '/i?' + query);
    var response = await http.get(url);

    Log.fine(
        "httpGet: response { body = ${response.body}, statusCode = ${response.statusCode} }");

    String data = response.body;
    final body = json.decode(response.body);
    bool success = response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body.containsKey('result');

    return new Response(data: data, success: success);
  }

  Future<Response> _httpPost(String query) async {
    Log.fine("httpPost: query = $query");

    var url = Uri.parse(configuration.serverUrl + '/i?' + query);
    var response = await http.get(url);

    Log.fine(
        "httpPost: response { body = ${response.body}, statusCode = ${response.statusCode} }");

    String data = response.body;
    final body = json.decode(response.body);
    bool success = response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body.containsKey('result');

    return new Response(data: data, success: success);
  }

  /// Fetch fresh remote config values from server and store locally.
  Future<Response> fetchRemoteConfig() async {
    Log.info("FetchRemoteConfig");

    if (!consents.checkConsentInternal(Consents.RemoteConfig)) {
      return Response(
        data: '',
        success: false,
      );
    }

    DeviceMetrics metrics = await DeviceMetrics.build();
    Map<String, dynamic> requestParams = _requestBuilder.baseParams();

    requestParams['method'] = 'fetch_remote_config';
    requestParams['metrics'] = jsonEncode(metrics.metricsToJson());

    String query = _requestBuilder.buildRequest(requestParams);
    Response response;
    if (configuration.enablePost) {
      response = await _httpGet(query);
    } else {
      response = await _httpPost(query);
    }

    if (response.success) {
      _remoteConfigRepository.removeAll();
      RemoteConfig remoteConfig = RemoteConfig(data: response.data);
      _remoteConfigRepository.insert(remoteConfig);
      _configs = json.decode(remoteConfig.data);
    }

    Log.fine("FetchRemoteConfig: response = ${response.toString()}");
    return response;
  }

  @override
  void onConsentChanged(List<String> updatedConsents, bool newConsentValue) {
    if (updatedConsents.contains(Consents.RemoteConfig) && !newConsentValue) {
      _configs.clear();
      _remoteConfigRepository.removeAll();
    }
  }
}
