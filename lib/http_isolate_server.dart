library sci_http_isolate_server;

import 'dart:isolate';
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'http_isolate.dart';
import 'isolate_server.dart';

typedef Future<IsolateHttpResponse> ProcessHttpRequest(
    IsolateHttpRequest request);

class HttpIsolateServer {
  static Logger logger = new Logger("HttpIsolateServer");

  IsolateServer server;
  ProcessHttpRequest httpRequestHandler;

  HttpIsolateServer(SendPort sendPort, this.httpRequestHandler) {
    server = new IsolateServer(sendPort, requestHandler: _requestHandler);
  }

  void _logRequest(IsolateHttpRequest httpRequest) {
    var map = new Map.from(httpRequest.toJson());
    map.remove("body");
//    logger.finest("_logRequest : httpRequest ${map}");
  }

  Future _requestHandler(
      IsolateServerRequest request, IsolateServerResponse response) {
    return request.stream.first.then((requestJson) {
      if (requestJson == null) return _onError(response, null, null);
      var httpRequest;
      try {
        httpRequest = new IsolateHttpRequest.fromJson(requestJson);
        _logRequest(httpRequest);
      } catch (e, st) {
        return _onError(response, e, st);
      }

      return _httpRequestHandler(httpRequest)
          .then((IsolateHttpResponse httpResponse) {
        if (httpResponse == null) return _onError(response, null, null);
        var controller = new StreamController();
        var doneFuture = response.addStream(controller.stream);
        controller..add(httpResponse.statusCode)..add(httpResponse.headers);
        controller.addStream(httpResponse.bodyStream).whenComplete(() {
          controller.close();
        });

        return doneFuture;
      });
    });
  }

  void _onError(IsolateServerResponse response, e, st) {
    logger.severe("", e, st);
    response.addStream(new Stream.fromIterable(
        [500, {}, UTF8.encode("Internal server error")]));
  }

  Future<IsolateHttpResponse> _httpRequestHandler(IsolateHttpRequest request) {
    return new Future.sync(() {
      return httpRequestHandler(request);
    }).catchError((e, st) {
      logger.severe("", e, st);
      return new IsolateHttpResponse.fromString(
          500, {}, "Internal server error");
    });
  }
}
