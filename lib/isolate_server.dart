library isolate_server;

import 'dart:isolate';
import 'dart:async';
import 'package:isolate_server/isolate_stream.dart';
import 'package:logging/logging.dart';

typedef Future ProcessRequest(
    IsolateServerRequest request, IsolateServerResponse response);

class IsolateServer {
  static final log = new Logger("IsolateServer");

  ReceivePort _receivePort;
  ProcessRequest _requestHandler;
  SendPort _logPort;

  IsolateServer(SendPort sendPort, {ProcessRequest requestHandler}) {
    _requestHandler = requestHandler == null ? processRequest : requestHandler;
    _receivePort = new ReceivePort();
    _receivePort.listen(_onMessage);
    sendPort.send(_receivePort.sendPort);
  }

  void _onMessage(List args) {
//    log.finest(args);
    if (args == null) {
      _receivePort.close();
    }
    if (args.length == 1) {
      _logPort = (args[0]);
    } else if (args.length == 3) {
      _onRequest(args[0], args[1], args[2]);
    }
  }

  void sendLog(String message) {
    if (_logPort != null) _logPort.send(message);
  }

  void _onRequest(
      SendPort _handShackeSendPort,
      SendPort _requestStreamConsumerCommandSendPort,
      SendPort _responseStreamSendPort) {
//    log.finest("_onRequest");

    ReceivePort _requestStreamReceivePort = new ReceivePort();
    ReceivePort _responseStreamConsumerCommandReceivePort = new ReceivePort();

    IsolateServerRequest request = new IsolateServerRequest(
        _requestStreamReceivePort, _requestStreamConsumerCommandSendPort);
    IsolateServerResponse response = new IsolateServerResponse(
        _responseStreamConsumerCommandReceivePort, _responseStreamSendPort);

    _handShackeSendPort.send([
      _requestStreamReceivePort.sendPort,
      _responseStreamConsumerCommandReceivePort.sendPort
    ]);

    _requestHandler(request, response).then((_) {
//      log.finest("_onRequest close");
      request.close();
      response.close();
    }).catchError((e) {
      log.warning("_onRequest ", e);
    });
  }

  Future processRequest(
      IsolateServerRequest request, IsolateServerResponse response) {
    return request.stream.pipe(response);
  }
}

class IsolateServerRequest {
  IsolateStream _workerStream;
  IsolateServerRequest(ReceivePort _requestStreamReceivePort,
      SendPort _requestStreamConsumerCommandSendPort) {
    _workerStream = new IsolateStream(
        _requestStreamReceivePort, _requestStreamConsumerCommandSendPort);
  }
  Stream get stream => _workerStream.stream;
  Future close() => _workerStream.close();
}

class IsolateServerResponse implements StreamConsumer {
  IsolateStreamConsumer _streamConsumer;
  IsolateServerResponse(ReceivePort _responseStreamConsumerCommandReceivePort,
      SendPort _responseStreamSendPort) {
    _streamConsumer = new IsolateStreamConsumer(
        _responseStreamConsumerCommandReceivePort, _responseStreamSendPort);
  }
  @override
  Future addStream(Stream stream) => _streamConsumer.addStream(stream);
  @override
  Future close() => _streamConsumer.close();
}
