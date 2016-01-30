import 'dart:isolate';
import 'dart:async';
import 'package:shelf/shelf.dart' as shelf;
import 'package:isolate_server/shelf_isolate.dart' as scishelf;
import 'package:isolate_server/shelf_isolate_log.dart' as scishelflog;


void main(List<String> args, SendPort replyTo) {

  print("Shelf started");

  var handler = const shelf.Pipeline()
      .addMiddleware(scishelflog.logRequests())
      .addHandler(_handler);

  scishelf.serve(handler, replyTo).then((server) {
    print('Serving at http://${server}');
  });
}

Future<shelf.Response> _handler(shelf.Request request) async {
  return new shelf.Response.ok("This response was generated from a worker isolate");
}
