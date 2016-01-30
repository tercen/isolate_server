import 'dart:html';
import 'package:isolate_server/http_isolate_client.dart';

main() {
  var client = new HttpIsolateClient(Uri.parse("server_shelf.dart"));

  client.get("/").then((response) {
    document.body.text =
        "statusCode : ${response.statusCode} , headers : ${response.headers} , body : ${response.body}";
  });
}
