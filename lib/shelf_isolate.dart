library shelf.isolate;

import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';

import 'package:shelf/shelf.dart';
import 'package:shelf/src/util.dart';

import 'http_isolate.dart';
import 'http_isolate_server.dart';

Future<HttpIsolateServer> serve(Handler handler, SendPort sendPort,
    {int backlog}) async {
  if (backlog == null) backlog = 0;
  return new HttpIsolateServer(sendPort, (request) {
    return handleRequest(request, handler);
  });
}

Future<IsolateHttpResponse> handleRequest(
    IsolateHttpRequest request, Handler handler) {
  var shelfRequest;
  try {
    shelfRequest = _fromHttpRequest(request);
  } catch (error, stackTrace) {
    var response = _logError('Error parsing request.\n$error', stackTrace);
    return _writeResponse(response);
  }

  return catchTopLevelErrors(() => handler(shelfRequest), (error, stackTrace) {
    if (error is HijackException) {
      // A HijackException should bypass the response-writing logic entirely.
      if (!shelfRequest.canHijack) throw error;

      // If the request wasn't hijacked, we shouldn't be seeing this exception.
      return _logError(
          "Caught HijackException, but the request wasn't hijacked.",
          stackTrace);
    }

    return _logError('Error thrown by handler.\n$error', stackTrace);
  }).then((response) {
    if (response == null) {
      return _writeResponse(_logError('null response from handler.'));
    }

    return _writeResponse(response);
  }).catchError((error, stackTrace) {
    // Ignore HijackExceptions.
    if (error is! HijackException) throw error;
  });
}

/// Creates a new [Request] from the provided [HttpRequest].
Request _fromHttpRequest(IsolateHttpRequest request) {
  var headers = {};
  request.headers.forEach((k, v) {
    // Multiple header values are joined with commas.
    // See http://tools.ietf.org/html/draft-ietf-httpbis-p1-messaging-21#page-22
//    headers[k] = v.join(',');
    headers[k] = v;
  });

  var rbody;
  if (request.body != null) {
    if (request.body is String) {
      rbody = request.body;
    } else if (request.body is Uint8List) {
      rbody = new Stream.fromIterable([request.body]);
    } else {
      throw "wrong body type";
    }
  }

  return new Request(request.method, request.url,
      protocolVersion: "1.1", headers: headers, body: rbody);
}

Future<IsolateHttpResponse> _writeResponse(Response response) {
  if (response.context.containsKey("shelf.io.buffer_output")) {
    throw "_writeResponse : not implemented : shelf.io.buffer_output";
  }

  return new Future.sync(() {
    var headers = {};

    response.headers.forEach((header, value) {
      if (value == null) return;
      headers[header] = value;
    });

    if (!response.headers.containsKey("server")) {
      headers["server"] = 'Tercen isolate server with Shelf';
    }

    if (!response.headers.containsKey("date")) {
      headers["date"] = new DateTime.now().toUtc().toIso8601String();
    }

    return new IsolateHttpResponse(
        response.statusCode, headers, response.read());
  });
}

Response _logError(String message, [StackTrace stackTrace]) {
  print('ERROR - ${new DateTime.now()}');
  print(message);
  print(stackTrace);
  return new Response.internalServerError();
}
