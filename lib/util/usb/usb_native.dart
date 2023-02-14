

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:typed_data';

import 'package:utils/core/error.dart';
import 'package:utils/util/storage/index.dart';

// import 'package:quick_usb/quick_usb.dart' as quick_usb;
import 'package:utils/util/usb/usb.dart';

import '../log.dart';


class UsbManager {

  static Future<List<UsbDevice>?> listDevices() async {
    return null;
    /*
    await quick_usb.QuickUsb.init();

    const _TAG = "UsbManager/QuickUsb";
    try {
      return (await quick_usb.QuickUsb.getDeviceList()).map((elem) => UsbDevice(elem, false)).toList();
    } catch (e) {
      Log.e(_TAG, () => "getUsbDevice() error: ", e);
      return null;
    } finally {
      await quick_usb.QuickUsb.exit();
    }
     */
  }

}

class UsbDeviceWeb extends UsbDevice {

  UsbDeviceWeb(dynamic raw, bool isWeb): super.build(raw, isWeb);

  @override
  Future<void> claimInterface(UsbInterface interface) {
    // TODO: implement claimInterface
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  Future<List<UsbConfiguration>> getConfigurations() {
    // TODO: implement getConfigurations
    throw UnimplementedError();
  }

  @override
  Future<bool> hasPermission() {
    // TODO: implement hasPermission
    throw UnimplementedError();
  }

  @override
  // TODO: implement identifier
  String get identifier => throw UnimplementedError();

  @override
  Future<bool> open() {
    // TODO: implement open
    throw UnimplementedError();
  }

  @override
  // TODO: implement productId
  int get productId => throw UnimplementedError();

  @override
  Future<Uint8List> read(UsbEndpoint endpoint, int maxLength) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  Future<void> releaseInterface(UsbInterface interface) {
    // TODO: implement releaseInterface
    throw UnimplementedError();
  }

  @override
  Future<void> requestPermission() {
    // TODO: implement requestPermission
    throw UnimplementedError();
  }

  @override
  Future<void> selectConfiguration(UsbConfiguration configuration) {
    // TODO: implement selectConfiguration
    throw UnimplementedError();
  }

  @override
  // TODO: implement vendorId
  int get vendorId => throw UnimplementedError();

  @override
  Future<int> write(UsbEndpoint endpoint, Uint8List data) {
    // TODO: implement write
    throw UnimplementedError();
  }

}

class UsbDeviceQuick extends UsbDevice {
  UsbDeviceQuick(dynamic raw, bool isWeb): super.build(raw, isWeb);

  @override
  Future<void> claimInterface(UsbInterface interface) {
    // TODO: implement claimInterface
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  Future<List<UsbConfiguration>?> getConfigurations() {
    // TODO: implement getConfigurations
    throw UnimplementedError();
  }

  @override
  Future<bool> hasPermission() {
    // TODO: implement hasPermission
    throw UnimplementedError();
  }

  @override
  // TODO: implement identifier
  String get identifier => throw UnimplementedError();

  @override
  Future<bool> open() {
    // TODO: implement open
    throw UnimplementedError();
  }

  @override
  // TODO: implement productId
  int get productId => throw UnimplementedError();

  @override
  Future<Uint8List> read(UsbEndpoint endpoint, int maxLength) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  Future<void> releaseInterface(UsbInterface interface) {
    // TODO: implement releaseInterface
    throw UnimplementedError();
  }

  @override
  Future<void> requestPermission() {
    // TODO: implement requestPermission
    throw UnimplementedError();
  }

  @override
  Future<void> selectConfiguration(UsbConfiguration configuration) {
    // TODO: implement selectConfiguration
    throw UnimplementedError();
  }

  @override
  // TODO: implement vendorId
  int get vendorId => throw UnimplementedError();

  @override
  Future<int> write(UsbEndpoint endpoint, Uint8List data) {
    // TODO: implement write
    throw UnimplementedError();
  }
}

/*
class UsbDeviceQuick extends UsbDevice<quick_usb.UsbDevice> {
  UsbDeviceQuick(dynamic raw, bool isWeb): super.build(raw, isWeb);

  @override
  String get identifier => raw.identifier;

  @override
  int get productId => raw.productId;

  @override
  int get vendorId => raw.vendorId;

  Future<bool> open() async {
    return await quick_usb.QuickUsb.openDevice(raw);
  }

  Future<void> close() async {
    await quick_usb.QuickUsb.closeDevice();
  }

  Future<List<UsbConfiguration>?> getConfigurations() async {
    var cs = await Future.wait([0, raw.configurationCount].it().map((e) => quick_usb.QuickUsb.getConfiguration(e)));
    return cs.map((e) {
      var ifs = e.interfaces.mapList((e) => UsbInterface(e, e.id, e.endpoints.mapList((e) => UsbEndpoint(e, e.endpointNumber))));
      return UsbConfiguration(e, e.id, '${e.index}', ifs);
    }).toList();
  }

  @override
  Future<void> claimInterface(UsbInterface interface) {
    return quick_usb.QuickUsb.claimInterface(interface.raw);
  }

  @override
  Future<void> releaseInterface(UsbInterface interface) {
    return quick_usb.QuickUsb.releaseInterface(interface.raw);
  }

  @override
  Future<void> selectConfiguration(UsbConfiguration configuration) {
    return quick_usb.QuickUsb.setConfiguration(configuration.raw);
  }


  @override
  Future<bool> hasPermission() async {
    return quick_usb.QuickUsb.hasPermission(raw);
  }

  @override
  Future<void> requestPermission() async {
    return quick_usb.QuickUsb.requestPermission(raw);
  }


  @override
  Future<Uint8List> read(UsbEndpoint endpoint, int maxLength) {
    return quick_usb.QuickUsb.bulkTransferIn(endpoint.raw, maxLength);
  }

  @override
  Future<int> write(UsbEndpoint endpoint, Uint8List data) {
    return quick_usb.QuickUsb.bulkTransferOut(endpoint.raw, data);
  }

}

// */