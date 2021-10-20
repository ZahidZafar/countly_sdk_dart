import 'dart:convert';

import 'package:countly/helper/request_builder.dart';
import 'package:countly/model/Response.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/model/request.dart';
import 'package:countly/repository/request_repository.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class RequestsController {
  final log = Logger('RequestsController');

  bool isQueueBeingProcess = false;
  final Configuration _configuration;
  final RequestBuilder _requestBuilder;
  final RequestRepository _requestRepository;
  RequestsController(
      {required Configuration configuration,
      required RequestRepository requestRepository,
      required RequestBuilder requestBuilder})
      : _configuration = configuration,
        _requestRepository = requestRepository,
        _requestBuilder = requestBuilder;

  Future<void> addToRequestQueue(Map<String, dynamic> params) async {
    log.fine("addToRequestQueue: data = ${params.toString()}");

    String data = jsonEncode(params);
    Request request =
        Request(data: data, timestamp: DateTime.now().millisecondsSinceEpoch);

    log.fine("addRequestToQueue: request = ${request.toJson()}");

    int r = await _requestRepository.insert(request);
    await processRequestQueue();
  }

  Future<void> processRequestQueue() async {
    log.fine(
        "processRequestQueue: isQueueBeingProcess = $isQueueBeingProcess ");
    if (isQueueBeingProcess) {
      return;
    }

    isQueueBeingProcess = true;

    List<Request> requests = await _requestRepository.findAll();

    log.fine("processRequestQueue: count = ${requests.length} ");

    var client = http.Client();
    for (Request request in requests) {
      Response response = await _processRequest(client, request);
      if (!response.success) {
        log.fine("processRequestQueue: response = ${response.toString()}");
        break;
      }

      await _requestRepository.remove(request);
    }

    client.close();
    isQueueBeingProcess = false;
  }

  Future<Response> _processRequest(http.Client client, Request request) async {
    if (_configuration.enablePost || request.data.length > 1800) {
      return await httpPost(client, request);
    } else {
      return await httpGet(client, request);
    }
  }

  Future<Response> httpGet(http.Client client, Request request) async {
    log.fine("httpGet: request = ${request.toJson()}");
    String query = _requestBuilder.buildRequest(jsonDecode(request.data));
    var url = Uri.parse(_configuration.serverUrl + '/i?' + query);
    var response = await client.get(url);

    log.fine(
        "httpGet: response { body = ${response.body}, statusCode = ${response.statusCode} }");

    String data = response.body;
    final body = json.decode(response.body);
    bool success = response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body.containsKey('result');

    return new Response(data: data, success: success);
  }

  Future<Response> httpPost(http.Client client, Request request) async {
    log.fine("httpPost: request = ${request.toJson()}");
    String query = _requestBuilder.buildRequest(jsonDecode(request.data));
    var url = Uri.parse(_configuration.serverUrl + '/i?');
    Map<String, String> headers = {
      'Content-type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    };
    var response = await client.post(url, body: query, headers: headers);

    log.fine(
        "httpPost: response { body = ${response.body}, statusCode = ${response.statusCode} }");

    String data = response.body;
    final body = json.decode(response.body);
    bool success = response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body.containsKey('result');

    return Response(data: data, success: success);
  }
}
