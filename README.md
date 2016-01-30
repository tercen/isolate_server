
# Package http_client is required 

see https://github.com/tercen/http_client

# Main isolate : HttpIsolateClient

``` dart
import 'dart:html';
import 'package:isolate_server/http_isolate_client.dart';

main() {
  var client = new HttpIsolateClient(Uri.parse("server_shelf.dart"));

  client.get("/").then((response) {
    document.body.text =
        "statusCode : ${response.statusCode} , headers : ${response.headers} , body : ${response.body}";
  });
}
```

# Web worker isolate : server_shelf.dart

Start a shelf using an isolate server.

``` dart
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
  return new shelf.Response.ok("This response was generated from a webworker");
}
```

# Web worker and transferable objects

Don't work in dartium. Tested in chrome.

``` dart
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
  var body = new Uint8List.fromList(UTF8.encode(
      'The response is sent using a transferable object, see : https://developer.mozilla.org/en-US/docs/Web/API/Transferable'
          ));

  return new shelf.Response.ok(new Stream.fromIterable([body]));
}
```

# Examples

see web folder ...