import 'dart:html';
import 'dart:async';
import 'dart:typed_data';
import 'package:isolate_server/isolate_client.dart';

main() {
  var client = new IsolateClient("server.dart");
  client.request((request, response) {
    var bytes = new Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    request.addStream(new Stream.fromIterable([
      {
        "msg": {"data": "hello"},
        "bytes": bytes
      }
    ]));
    response.stream.listen((data) {
      document.body.text = "recieved $data";
    });
  });
}
