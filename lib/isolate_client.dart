library isolate_client;

import 'dart:async';
import 'dart:isolate';
import 'package:isolate_server/isolate_stream.dart';
import 'package:logging/logging.dart';

class IsolateClient {
  static final log = new Logger("IsolateClient");

  String _url;
  SendPort _serverPort;
  Future _connectFuture;
  ReceivePort _logReceivePort;

  IsolateClient(this._url, [List<String> args]) {
    var _connectCompleter = new Completer();
    _connectFuture = _connectCompleter.future;
    _logReceivePort = new ReceivePort();
    _logReceivePort.listen((strlog) {
      log.finest("SERVER_LOGS : $strlog");
    });
    ReceivePort _connectReceivePort = new ReceivePort();
    _connectReceivePort.listen((server_port) {
      _serverPort = server_port;
      _serverPort.send([_logReceivePort.sendPort]);
      _connectReceivePort.close();
      _connectCompleter.complete();
    });
    args = args == null ? [] : args;
    Isolate.spawnUri(Uri.parse(_url), args, _connectReceivePort.sendPort);
  }

  Future request(
      send(IsolateClientRequest request, IsolateClientResponse response)) {
    return _connectFuture.then((_) {
      ReceivePort _handShackeReceivePort = new ReceivePort();
      ReceivePort _requestStreamConsumerCommandReceivePort = new ReceivePort();
      ReceivePort _responseStreamReceivePort = new ReceivePort();
      var _handShackeSub;
      _handShackeSub = _handShackeReceivePort.listen((List<SendPort> ports) {
        _handShackeReceivePort.close();
        _handShackeSub.cancel();
        SendPort _remoteRequestStreamSendPort = ports[0];
        SendPort _remoteResponseStreamConsumerCommandSendPort = ports[1];
        var request = new IsolateClientRequest(
            _requestStreamConsumerCommandReceivePort,
            _remoteRequestStreamSendPort);
        var response = new IsolateClientResponse(_responseStreamReceivePort,
            _remoteResponseStreamConsumerCommandSendPort);
        send(request, response);
      });
      _serverPort.send([
        _handShackeReceivePort.sendPort,
        _requestStreamConsumerCommandReceivePort.sendPort,
        _responseStreamReceivePort.sendPort
      ]);
    });
  }

  void close() {
    _serverPort.send(null);
  }
}

class IsolateClientResponse {
  IsolateStream _workerStream;

  IsolateClientResponse(ReceivePort _responseStreamReceivePort,
      SendPort _remoteResponseStreamConsumerCommandSendPort) {
    _workerStream = new IsolateStream(_responseStreamReceivePort,
        _remoteResponseStreamConsumerCommandSendPort);
  }

  Stream get stream => _workerStream.stream;
  Future close() => _workerStream.close();
}

class IsolateClientRequest implements StreamConsumer {
  IsolateStreamConsumer _streamConsumer;

  IsolateClientRequest(ReceivePort _requestStreamConsumerCommandReceivePort,
      SendPort _remoteRequestStreamSendPort)
      : super() {
    _streamConsumer = new IsolateStreamConsumer(
        _requestStreamConsumerCommandReceivePort, _remoteRequestStreamSendPort);
  }

  @override
  Future addStream(Stream stream) {
    return _streamConsumer.addStream(stream);
  }

  @override
  Future close() {
    return _streamConsumer.close();
  }
}
