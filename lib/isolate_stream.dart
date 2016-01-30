library isolate_stream;

import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';
import 'package:logging/logging.dart';

class IsolateStreamConsumer implements StreamConsumer {

  static final log = new Logger("IsolateStreamConsumer");

  ReceivePort _controlReceivePort;
  SendPort _sendPort;
  Stream _stream;
  StreamSubscription _sub;
  Completer _completer;
  bool _listen = false;

  IsolateStreamConsumer(this._controlReceivePort, this._sendPort) {
    _controlReceivePort.listen(_onControlMessage);
  } 
   
  void _onControlMessage(msg) {
//    log.finest("_onControlMessage $msg _listen:$_listen _stream:$_stream");
    if (msg == "listen") {
      _listen = true;
      _mayBeListen();
    }
    if (_sub == null) return;
    if (msg == "pause") {
      _sub.pause();
    } else if (msg == "resume") {
      _sub.resume();
    } else if (msg == "cancel") {
      close();
    }
  }

  void _mayBeListen() {
    if (_listen && _stream != null && _sub == null) {
      _sub = _stream.listen(_onData, onDone: _onDone, onError: _onError, cancelOnError: true);
    }
  }

  @override
  Future addStream(Stream stream) {
    if (_stream != null) {
//      log.warning("addStream _stream != null");
      return new Future.error("$this a stream is already in place");
    }
    _stream = stream;
    _mayBeListen();
    _completer = new Completer();
    return _completer.future;
  }

  void _onData(data) {
    if (data is TypedData){
      _sendPort.send([1, data.buffer]);
    } else
    _sendPort.send([1, data]);
  }

  void _onDone() {
    if (!_completer.isCompleted) {
      _sendPort.send([0, null]);
      _completer.complete();
    }
  }

  void _onError(e) {
//    log.warning("_onError $e");
    if (!_completer.isCompleted) {
      _sendPort.send([2, e.toString()]);
      _completer.completeError(e);
    }
  }

  @override
  Future close() {
    if (!_completer.isCompleted) {
      _sendPort.send([0, null]);
      _controlReceivePort.close();
      _completer.complete();
    }
    return _sub.cancel();
  }
}


class IsolateStream {

  static final log = new Logger("IsolateStream");

  StreamController _controller;
  ReceivePort _receivePort;
  SendPort _controlSendPort;
  bool _listen = false;

  IsolateStream(this._receivePort, this._controlSendPort) {
    _controller = new StreamController(onListen: _onListen, onPause: _onPause, onCancel: _onCancel, onResume: _onResume);
    _receivePort.listen(_onMessage);
  }
 
  void _onListen() {
    _controlSendPort.send("listen");
    _listen = true;
  }

  void _onPause() {
//    log.finest("_onPause");
    _controlSendPort.send("pause");
  }

  void _onCancel() {
//    log.finest("_onCancel");
    _controlSendPort.send("cancel");
    close();
  }

  void _onResume() {
//    log.finest("_onResume");
    _controlSendPort.send("resume");
  }
 
  void _onMessage(List args) {
    if (args == null) return;
    if (args.length == 2) {
      if (args[0] == 0) {
        close();
      } else if (args[0] == 1) {
        _controller.add(args[1]);
      } else if (args[0] == 2) {
        _controller.addError(args[1]);
        close();
      }
    }
  }

  Stream get stream => this._controller.stream;
  
  Future close() {
    _receivePort.close();
    return this._controller.close();
  }
}
