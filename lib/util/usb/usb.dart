

import 'dart:typed_data';

import 'package:utils/util/storage/index.dart';

import 'package:utils/util/usb/usb_native.dart'
  if (dart.library.js) 'package:utils/util/usb/usb_web.dart'
;

export 'package:utils/util/usb/usb_native.dart'
  if (dart.library.js) 'package:utils/util/usb/usb_web.dart'
;

abstract class UsbDevice<RAW_TYPE> {
  RAW_TYPE raw;
  bool isWeb;

  UsbDevice.build(this.raw, this.isWeb);

  factory UsbDevice(raw, bool isWeb) {
    return (isWeb ? UsbDeviceWeb(raw, isWeb) : UsbDeviceQuick(raw, isWeb)) as UsbDevice<RAW_TYPE>;
  }

  int get productId;
  String get identifier;
  int get vendorId;

  Future<bool> open();

  Future<void> close();

  Future<void> selectConfiguration(UsbConfiguration configuration);

  Future<List<UsbConfiguration>?> getConfigurations();

  Future<void> claimInterface(UsbInterface interface);

  Future<void> releaseInterface(UsbInterface interface);



  Future<bool> hasPermission();

  Future<void> requestPermission();


  Future<Uint8List> read(UsbEndpoint endpoint, int maxLength);

  Future<int> write(UsbEndpoint endpoint, Uint8List data);

}

class UsbConfiguration {
  int value;
  String name;
  List<UsbInterface> interfaces;

  dynamic raw;

  UsbConfiguration(this.raw, this.value, this.name, this.interfaces);

}

class UsbInterface {
  int value;
  List<UsbEndpoint> endpoints;

  dynamic raw;

  UsbInterface(this.raw, this.value, this.endpoints);
}

class UsbEndpoint {
  int value;

  dynamic raw;

  UsbEndpoint(this.raw, this.value);
}