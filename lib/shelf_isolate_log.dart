library sci.shelf.handlers.logger;

import 'package:shelf/shelf.dart';
import 'package:shelf/src/util.dart';

/// Middleware which prints the time of the request, the elapsed time for the
/// inner handlers, the response's status code and the request URI.
///
/// [logger] takes two parameters.
///
/// `msg` includes the request time, duration, request method, and requested
/// path.
///
/// For successful requests, `msg` also includes the status code.
///
/// When an error is thrown, `isError` is true and `msg` contains the error
/// description and stack trace.
Middleware logRequests({void logger(String msg, bool isError)}) =>
    (innerHandler) {
      if (logger == null) logger = _defaultLogger;

      return (request) {
        var startTime = new DateTime.now();
        var watch = new Stopwatch()..start();

        return catchTopLevelErrors(() => innerHandler(request),
            (error, stackTrace) {
          if (error is HijackException) throw error;
          var msg = _getErrorMessage(startTime, request.requestedUri,
              request.method, watch.elapsed, error, stackTrace);
          logger(msg, true);
          throw error;
        }).then((response) {
          var msg = _getMessage(startTime, response.statusCode,
              request.requestedUri, request.method, watch.elapsed);

          logger(msg, false);

          return response;
        });
      };
    };

String _getMessage(DateTime requestTime, int statusCode, Uri requestedUri,
    String method, Duration elapsedTime) {
  return '${requestTime}\t$elapsedTime\t$method\t[${statusCode}]\t'
      '${requestedUri.path}${requestedUri.query}';
}

String _getErrorMessage(DateTime requestTime, Uri requestedUri, String method,
    Duration elapsedTime, Object error, StackTrace stack) {
  var msg = '${requestTime}\t$elapsedTime\t$method\t${requestedUri.path}'
      '${requestedUri.query}\n$error';
   return msg;
}

void _defaultLogger(String msg, bool isError) {
  if (isError) {
    print('[ERROR] $msg');
  } else {
    print(msg);
  }
}
