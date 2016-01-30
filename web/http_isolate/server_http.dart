import 'dart:isolate';
import 'package:isolate_server/http_isolate_server.dart';
import 'package:isolate_server/http_isolate.dart';

void main(List<String> args, SendPort replyTo) {
  print("HttpIsolateServer started");

  new HttpIsolateServer(replyTo, (IsolateHttpRequest request) async {
    print("HttpIsolateServer request ${request.url}");

    return new IsolateHttpResponse.fromString(
        200, {}, "hello from HttpIsolateServer");
  });
}
