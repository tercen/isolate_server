import 'package:isolate_server/http_isolate_client.dart';

main() {
  var client = new HttpIsolateClient(Uri.parse("server_shelf.dart"));

  client.get("/").then((response) {
    print(
        "statusCode : ${response.statusCode} , headers : ${response.headers} , body : ${response.body}");
  });
}
