library sci_http_isolate;

import 'package:http_client/http_client.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

class IsolateHttpRequest {
  Map _data;

  IsolateHttpRequest(String method, url, Map<String, String> headers, body,
      {String responseType: "text", Encoding encoding: UTF8}) {
    Uri uri = url is String ? Uri.parse(url) : url;
    uri = uri.isAbsolute ? uri : Uri.base.resolveUri(uri);
    var enc = encoding == null ? UTF8 : encoding;
    _data = {};
    _data["method"] = method;
    _data["url"] = uri.toString();
    _data["headers"] = headers == null ? {} : headers;
    _data["body"] = body;
    _data["responseType"] = responseType;
    _data["encoding"] = enc.name;
  }

  IsolateHttpRequest.fromJson(Map m) {
    _data = m;
  }

  String get method => _data["method"];
  Uri get url => Uri.parse(_data["url"]);
  Map<String, String> get headers => _data["headers"];
  Object get body => _data["body"];

  String get responseType => _data["responseType"];
  String get encoding => _data["encoding"];

  Map toJson() => _data;
}

class IsolateHttpResponse implements http.Response {
  int statusCode;
  Map<String, String> headers;
  String responseType;
  Stream bodyStream;
  Object body;

  static Future<IsolateHttpResponse> fromResponseType(int statusCode,
      Map<String, String> headers, Stream bodyStream, String responseType) {
    return new Future.sync(() {
      var response = new IsolateHttpResponse(
          statusCode, headers, bodyStream, responseType);
      return response._prepareBody().then((_) {
        return response;
      });
    });
  }

  IsolateHttpResponse(this.statusCode, this.headers, this.bodyStream,
      [this.responseType]);

  IsolateHttpResponse.fromString(
      this.statusCode, this.headers, String strbody) {
    bodyStream =
        new Stream.fromIterable([UTF8.encode(strbody == null ? "" : strbody)]);
  }

  List<int> getListFromListOrByteBuffer(listOrByteBuffer) {
    var list;
    if (listOrByteBuffer is List) {
      list = listOrByteBuffer;
    } else if (listOrByteBuffer is ByteBuffer) {
      list = new Uint8List.view(listOrByteBuffer);
    } else {
      throw "_prepareBody wrong type ${listOrByteBuffer.runtimeType} must be List<int> or ByteBuffer";
    }
    return list;
  }

  Future _prepareBody() {
    return bodyStream.toList().then((list) {
      if (list.length == 1) {
        body = getListFromListOrByteBuffer(list.first);
      } else {
        var len = list.fold(
            0, (len, l) => len + getListFromListOrByteBuffer(l).length);
        body = new Uint8List(len);
        list.fold(0, (len, l) {
          var ll = getListFromListOrByteBuffer(l);
          (body as Uint8List).setRange(len, len + ll.length, ll);
          return len + ll.length;
        });
      }
      if (responseType != "arraybuffer") {
        body = UTF8.decode(body);
      }
      if (responseType == "arraybuffer") {
        body = (body as Uint8List).buffer;
      }
    }).then((_) {
      bodyStream = null;
    });
  }
}
