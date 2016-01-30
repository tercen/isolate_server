library sci_isolate_http_client;

import 'dart:convert';
import 'dart:async';
import 'package:logging/logging.dart';

import 'package:http_client/http_client.dart' as http;
import 'isolate_client.dart';
import 'http_isolate.dart';

class HttpIsolateClient implements http.HttpClient {
  static Logger logger = new Logger("HttpIsolateClient");
  IsolateClient _client;

  HttpIsolateClient(Uri serverUri, [List<String> args]) {
    _client = new IsolateClient(serverUri.toString(), args);
  }

  Future<http.Response> send(IsolateHttpRequest httpRequest) {
    _logRequest(httpRequest);
    var completer = new Completer();
    _client.request((request, response) {
      var jsonRequest = httpRequest.toJson();
      request.addStream(new Stream.fromIterable([jsonRequest]));
      response.stream.toList().then((list) {
        if (list.length < 3) throw " $this send list.length < 3";
        var statusCode = list[0];
        var headers = list[1];
        var bodyStream = new Stream.fromIterable(list.sublist(2));
        return IsolateHttpResponse
            .fromResponseType(
                statusCode, headers, bodyStream, httpRequest.responseType)
            .then(completer.complete);
      });
    }).catchError((e, st) {
      completer.completeError(e, st);
    });
    return completer.future;
  }

  void _logRequest(IsolateHttpRequest httpRequest) {
    var map = new Map.from(httpRequest.toJson());
    map.remove("body");
//    logger.finest("_logRequest : httpRequest ${map}");
  }

  @override
  void close({bool force}) {
    _client.close();
  }

  @override
  Future<http.Response> delete(url, {Map<String, String> headers}) {
    return send(new IsolateHttpRequest("DELETE", url, headers, null));
  }

  @override
  Future<http.Response> get(url,
      {Map<String, String> headers, String responseType}) {
    return send(new IsolateHttpRequest("GET", url, headers, null,
        responseType: responseType));
  }

  @override
  Future<http.Response> head(url, {Map<String, String> headers}) {
    return send(new IsolateHttpRequest("HEAD", url, headers, null));
  }

  @override
  Future<http.Response> post(url,
      {Map<String, String> headers,
      body,
      String responseType: "text",
      Encoding encoding: UTF8}) {
    return send(new IsolateHttpRequest("POST", url, headers, body,
        responseType: responseType, encoding: encoding));
  }

  @override
  Future<http.Response> put(url,
      {Map<String, String> headers,
      body,
      String responseType,
      Encoding encoding}) {
    return send(new IsolateHttpRequest("PUT", url, headers, body,
        responseType: responseType, encoding: encoding));
  }

  @override
  Uri resolveUri(Uri uri, String path) {
    return http.HttpClient.ResolveUri(uri, path);
  }
}
