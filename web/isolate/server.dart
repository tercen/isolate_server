import 'dart:isolate';
import 'dart:async';
import 'package:isolate_server/isolate_server.dart';

IsolateServer server;

void main(List<String> args, SendPort replyTo) {
  server = new IsolateServer(replyTo, requestHandler:
      (IsolateServerRequest request, IsolateServerResponse response) {
    return request.stream.toList().then((list) {
      return response.addStream(new Stream.fromIterable([list.toString()]));
    });
  });

}
