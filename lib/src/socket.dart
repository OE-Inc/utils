import 'dart:typed_data';

import 'package:socket_io/socket_io.dart';
import 'package:socket_io_client/socket_io_client.dart' as Client;

import 'log.dart';

/*
Event List:
  'connect',
  'connect_error',
  'connect_timeout',
  'connecting',
  'disconnect',
  'error',
  'reconnect',
  'reconnect_attempt',
  'reconnect_failed',
  'reconnect_error',
  'reconnecting',
  'ping',
  'pong'
*/


abstract class SimpleSocketListener<SOCKET> {
  void onData(Uint8List data, SOCKET socket);
  void onConnectChanged(SOCKET socket, bool connected, bool reconnect);
  void onError(SOCKET socket, dynamic error);
}

const String _TAG = "SimpleSocket";

class SimpleSocket<T> {
  String  address;
  int     port;
  SimpleSocketListener<T>    listener;

  SimpleSocket(this.address, this.port, this.listener);
}

class SocketClientEvent {
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

    ping = "ping",
    pong = "pong"
  ;
}

class SocketClient extends SimpleSocket {
  Client.Socket socket;
  String        dataEvent;

  SocketClient(String address, int port, SimpleSocketListener<Client.Socket> listener, { this.dataEvent, }) : super(address, port, listener) {
    _init();
  }

  void send(String event, [dynamic data]) {
    socket.emit(event, data);
  }

  _init() {
    socket = Client.io('$address');

    socket.on(SocketClientEvent.connect, (_) {
      Log.d(_TAG, "client connect: $_");
      listener.onConnectChanged(this, true, false);
    });

    socket.on(SocketClientEvent.disconnect, (_) {
      Log.d(_TAG, "client disconnect: $_");
      listener.onConnectChanged(this, false, false);
    });

    socket.on(dataEvent, (data) => listener.onData(data, socket));

    socket.on('event', (data) => { Log.d(_TAG, "socket($this) event: $data)") });
  }

  @override
  String toString() {
    return "SocketClient { address: $address, port: $port, socket: $socket, }";
  }
}

class SocketServer extends SimpleSocket {
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