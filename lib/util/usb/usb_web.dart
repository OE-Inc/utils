

import 'dart:typed_data';

import 'package:utils/core/error.dart';
import 'package:utils/util/storage/index.dart';

import 'package:utils/util/usb/usb.dart';
import 'package:usb_device/usb_device.dart' as usb_web;

import '../log.dart';

class UsbManager {

  static usb_web.UsbDevice? __usbWeb;
  static usb_web.UsbDevice get _usbWeb => __usbWeb ??= usb_web.UsbDevice();

  static Future<List<UsbDevice>> listDevices() async {
    const _TAG = "UsbManager/web";

    var support = await _usbWeb.isSupported();
    if (!support) {
      Log.d(_TAG, () => "usb web not support.");
      return [];
    }

    return (await Future.wait((await _usbWeb.pairedDevices).map((elem) => _usbWeb.getPairedDeviceInfo(elem))))
        .map((elem) => UsbDevice(elem, true))
        .toList()
    ;
  }

}

class UsbDeviceWeb extends UsbDevice<usb_web.USBDeviceInfo> {
  UsbDeviceWeb(dynamic raw, bool isWeb): super.build(raw, isWeb);

  @override
  String get identifier => raw.serialNumber;

  @override
  int get productId => raw.productId;

  @override
  int get vendorId => raw.vendorId;

  Future<bool> open() async {
    return await UsbManager._usbWeb.open(raw);
  }

  Future<void> close() async {
    return await UsbManager._usbWeb.close(raw);
  }

  Future<List<UsbConfiguration>?> getConfigurations() async {
    return (await UsbManager._usbWeb.getAvailableConfigurations(raw))
        .map((e) {
      var ifs = e.usbInterfaces!.mapList((e) => UsbInterface(e, e.interfaceNumber, e.alternatesInterface!.first.endpoints!.mapList((e) => UsbEndpoint(e, e.endpointNumber))));
      return UsbConfiguration(e, e.configurationValue!, e.configurationName!, ifs);
    }).toList();
  }

  Future<void> selectConfiguration(UsbConfiguration configuration) async {
    return await UsbManager._usbWeb.selectConfiguration(raw, configuration.value);
  }

  Future<void> claimInterface(UsbInterface interface) async {
    return await UsbManager._usbWeb.claimInterface(raw, interface.value);
  }

  Future<void> releaseInterface(UsbInterface interface) async {
    return await UsbManager._usbWeb.releaseInterface(raw, interface.value);
  }

  @override
  Future<Uint8List> read(UsbEndpoint endpoint, int maxLength) async {
    var result = await UsbManager._usbWeb.transferIn(raw, endpoint.value, maxLength);

    if (result.status == usb_web.StatusResponse.empty_data) return Uint8List(0);
    else if (result.status == usb_web.StatusResponse.ok) return result.data;
    else throw RuntimeException('read error, status: ${result.status}');
  }

  @override
  Future<int> write(UsbEndpoint endpoint, Uint8List data) async {
    var result = await UsbManager._usbWeb.transferOut(raw, endpoint.value, data.buffer);

    if (result.status == usb_web.StatusResponse.empty_data) return 0;
    else if (result.status == usb_web.StatusResponse.ok) return data.length;
    else throw RuntimeException('write error, status: ${result.status}');
  }

  @override
  Future<bool> hasPermission() async {
    return true;
  }

  @override
  Future<void> requestPermission() async {
    // do nothing.
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
