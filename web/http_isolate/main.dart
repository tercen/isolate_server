import 'package:isolate_server/http_isolate_client.dart';

main() {
  var client = new HttpIsolateClient(Uri.parse("server_http.dart"));

  client.get("/").then((response) {
    print("statusCode : ${response.statusCode}");
    print("headers : ${response.headers}");
    print("body : ${response.body}");
  });
}
