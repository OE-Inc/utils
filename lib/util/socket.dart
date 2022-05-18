import 'dart:async';
import 'dart:io' as ioWs;
// import 'dart:html' as htmlWs;
import 'package:flutter/foundation.dart';

import '_socket_web.dart' if (dart.library.js) 'dart:html' as htmlWs;
import 'dart:typed_data';

import 'package:utils/util/running_env.dart';
import 'package:utils/util/storage/index.dart';
import 'package:socket_io_client/socket_io_client.dart' as SocketIo;

import 'log.dart';
import 'multi_completer.dart';

const String _TAG = "WebSocketClient";

class WebSocketEvent {
  static const String
    connect = "connect",
    connect_error = "connect_error",
    connect_timeout = "connect_timeout",
    connecting = "connecting",
    disconnect = "disconnect",
    error = "error",
    reconnect = "reconnect",
    reconnect_attempt = "reconnect_attempt",
    reconnect_failed = "reconnect_failed",
    reconnect_error = "reconnect_error",
    reconnecting = "reconnecting",

    data = "data",
    close = "close",

    ping = "ping",
    pong = "pong"
  ;
}

class CommInternetAddress {

  static ioWs.InternetAddress? get anyIPv4 => RunningEnv.isWeb ? null : ioWs.InternetAddress.anyIPv4;
  static ioWs.InternetAddress? get anyIPv6 => RunningEnv.isWeb ? null : ioWs.InternetAddress.anyIPv6;

  static ioWs.InternetAddress? fromRawAddress(Uint8List bytes) => RunningEnv.isWeb ? null : ioWs.InternetAddress.fromRawAddress(bytes);

}

abstract class SocketClient<SOCKET_TYPE> extends ChangeNotifier {

  String      address;
  String      state = WebSocketEvent.disconnect;

  SOCKET_TYPE? _socket;
  SOCKET_TYPE get socket => _socket!;
  set socket(SOCKET_TYPE s) => _socket = s;

  int         timeout;
  int         _autoConnect = 0;
  bool get    autoConnect => _autoConnect > 0;

  bool get    isConnected => state == WebSocketEvent.connect;

  @protected
  StreamSubscription? sub;

  List<void Function(Uint8List data)> _listeners = [];

  SocketClient(this.address, { this.timeout = 15*1000, });

  Future<void> initSocket() async {
    Log.d(_TAG, () => "initSocket, autoConnect: $autoConnect, address: $address.");

    await doInitSocket();
    setState(WebSocketEvent.connect, reason: 'init success');
  }

  Future<void> startAutoConnect(bool autoConnect, { bool onlyForeground = false, int interval = 5*1000, }) async {
    var ac = this._autoConnect = autoConnect ? utc() : 0;

    while (ac == _autoConnect && ac > 0) {
      try {
        if (!isConnected && _socket == null && (!onlyForeground || RunningEnv.foreground)) {
          await initSocket();
        }
      } catch (e) {
        Log.e(_TAG, () => "autoConnect socket error: $this, error: $e", e);
      }

      await delay(interval);
    }
  }

  Future<void> doInitSocket();

  void send(Uint8List data);

  void doClose();

  void setState(String newState, { String? reason, }) {
    Log.d(_TAG, () => "setState: $state => $newState, reason: $reason.");

    state = newState;

    var closed = newState == WebSocketEvent.close;
    if (closed) {
      close(updateState: false);
    }

    notifyListeners();
  }


  void onData(void Function(Uint8List data) onData) {
    _listeners.add(onData);
  }

  void close({ updateState = true, }) {
    doClose();

    sub?.cancel();
    sub = null;
    _socket = null;

    if (updateState)
      setState(WebSocketEvent.close, reason: 'close()');
  }

  @override
  String toString() {
    return "$runtimeType { addr: $address, state: $state, socket: $_socket, }";
  }

}

abstract class WebSocketClient<SOCKET_TYPE> extends SocketClient<SOCKET_TYPE> {

  WebSocketClient(String address) : super(address);

  static WebSocketClient fromAddress(String address) {
    return (RunningEnv.isWeb ? HtmlWebSocketClient(address) : IoWebSocketClient(address)) as WebSocketClient;
  }

}

class HtmlWebSocketClient extends WebSocketClient<htmlWs.WebSocket> {

  HtmlWebSocketClient(String address) : super(address);


  Future<void> doInitSocket() async {
    // Log.d(_TAG, () => "doInitSocket: $address.");

    socket = await htmlWs.WebSocket(address);
    socket.binaryType = "arraybuffer";

    sub = socket.onMessage.listen((event) {
      var data = event.data;
      Uint8List bytes;
      if (data is String) bytes = data.utf8Bytes;
      else if (data is ByteBuffer) bytes = data.asUint8List();
      else bytes = data;

      for (var l in _listeners) {
        l(bytes);
      }
    },
      onError: (e) => setState(WebSocketEvent.error, reason: 'onError: $e'),
      onDone: () => setState(WebSocketEvent.close, reason: 'onDone'),
      cancelOnError: true,
    );

    await delay(5*1000, continueDelay: () => socket.readyState != htmlWs.WebSocket.OPEN, checkInterval: 10);
  }

  @override
  void doClose() {
    var s = socket;
    if (s == null) return;

    if (s.readyState == ioWs.WebSocket.closed || s.readyState == ioWs.WebSocket.closing)
      return;

    s.close();
  }

  @override
  void send(Uint8List data) {
    socket.send(data);
  }

}


class IoWebSocketClient extends WebSocketClient<ioWs.WebSocket> {

  IoWebSocketClient(String address) : super(address);


  Future<void> doInitSocket() async {
    Log.d(_TAG, () => "initSocket: $address.");

    socket = await ioWs.WebSocket.connect(address);

    sub = socket.listen((event) {
      var bytes = event is String ? event.utf8Bytes : event;
      for (var l in _listeners) {
        l(bytes);
      }
    },
      onError: (e) => setState(WebSocketEvent.error, reason: 'onError: $e'),
      onDone: () => setState(WebSocketEvent.close, reason: 'onDone: ${socket.closeCode}/${socket.closeReason}'),
      cancelOnError: true,
    );
  }

  @override
  void doClose() {
    var s = socket;
    if (s == null) return;

    if (s.readyState == ioWs.WebSocket.closed || s.readyState == ioWs.WebSocket.closing)
      return;

    s.close();
  }

  @override
  void send(Uint8List data) {
    socket.add(data);
  }

}


class SocketIoClient extends SocketClient<SocketIo.Socket> {

  SocketIoClient(String address) : super(address);

  @override
  Future<void> doInitSocket() async {
    Log.d(_TAG, () => "initSocket: $address.");

    socket = SocketIo.io(address, <String, dynamic> {
      'transports': ['websocket'],
    });

    socket.on(WebSocketEvent.connect, (_) {
      Log.d(_TAG, () => "client connect: $_");
      setState(WebSocketEvent.connect, reason: 'onConnect: $_');
    });

    socket.on(WebSocketEvent.disconnect, (_) {
      Log.d(_TAG, () => "client disconnect: $_");
      setState(WebSocketEvent.disconnect, reason: 'onDisconnect: $_');
    });

    // socket.on('event', (data) => { Log.d(_TAG, () => "socket($this) event: $data)") });

    socket.on('message', (event) {
      var bytes = event is String ? event.utf8Bytes : event;
      for (var l in _listeners) {
        l(bytes);
      }
    });

    socket.on(WebSocketEvent.error, (data) {
      Log.e(_TAG, () => "socket($this) on error: $data)");
      setState(WebSocketEvent.error, reason: 'onError: $data');
    });
  }

  @override
  void send(Uint8List data) {
    socket.send(data);
  }

  @override
  void doClose() {
    var s = socket;
    if (s == null) return;

    if (s.disconnected)
      return;

    s.close();
  }

}


/*
class WebSocketServer extends SimpleSocket {
  Server          server;
  List<Socket>    sockets = [];

  SocketServer(String address, int port, SimpleSocketListener<Socket> listener) : super(address, port, listener) {
    throw UnimplementedError("should complete later.");
    _init();
  }

  void broadcast(String event, [dynamic data]) {
    for (Socket socket in sockets) {
      socket.emit(event, data);
    }
  }

  void send(Socket socket, String event, [dynamic data]) {
    socket.emit(event, data);
  }

  void _initClient(Socket client) {
    sockets.add(client);

    client.on('msg', (data) {
      print('data from default => $data');
      client.emit('fromServer', "ok");
    });
  }

  void _init() {
    server = new Server();

    server.on('connection', (Socket client) {
      print('socket connected: $client');
      _initClient(client);
    });

    server.on("error", (error) {
      listener.onError(null, error);
    });

    server.listen(port);
  }
}

 */