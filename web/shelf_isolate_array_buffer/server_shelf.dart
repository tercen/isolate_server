import 'dart:isolate';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:isolate_server/shelf_isolate.dart' as scishelf;
import 'package:isolate_server/enable_web_worker_array_buffer.dart'
    as sciarraybuffer;
import 'package:isolate_server/shelf_isolate_log.dart' as scishelflog;

void main(List<String> args, SendPort replyTo) {
  print("Shelf started");

  sciarraybuffer.enableWebWorkerArrayBuffer();

  var handler = const shelf.Pipeline()
      .addMiddleware(scishelflog.logRequests())
      .addHandler(_handler);

  scishelf.serve(handler, replyTo).then((server) {
    print('Serving at http://${server}');
  });
}

Future<shelf.Response> _handler(shelf.Request request) async {

  var bytes = new Uint8List.fromList(UTF8.encode(
      'The response is sent using a transferable object, see : https://developer.mozilla.org/en-US/docs/Web/API/Transferable'));

  return new shelf.Response.ok(new Stream.fromIterable([bytes]));
}
