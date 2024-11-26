/*
 * @Author: Albert
 * @Date: 2024-11-25 09:51:00
 * @Last Modified by: Albert
 * @Last Modified time: 2024-11-25 09:51:00
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:web3_dapp_browser/src/dapp_method.dart';

class JsCallbackObjectModel {
  int chainId = 0x1;

  JsCallbackObjectModel.fromJson(Map<String, dynamic> json) {
    if (json['chainId'] == null) return;
    final cId = int.tryParse(json['chainId'].toString());
    chainId = cId!;
  }
}

class JsCallbackModel {
  int id = 0;
  String name = "";
  Map<String, dynamic> object = {};
  String network = "";
  late JsCallbackObjectModel objModel;

  JsCallbackModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    object = json['object'];
    network = json['network'];
    objModel = JsCallbackObjectModel.fromJson(object);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['object'] = object;
    data['network'] = network;
    return data;
  }

  // -------------------------
  // JSON Extraction Helpers
  // -------------------------

  DAppMethod? extractMethod(Map<String, dynamic> json) {
    final method = json['method'] as String?;
    return DAppMethod.values.firstWhere(
      (e) => e.name == method,
    );
  }

  Uint8List? extractMessage(Map<String, dynamic> json) {
    final message = json['data'] as String?;
    return message != null ? base64Decode(message) : null;
  }

  int? extractEthereumChainId(Map<String, dynamic> json) {
    return json['chainId'] as int?;
  }

  String? extractRaw(Map<String, dynamic> json) {
    return json['raw'] as String?;
  }
}

class JsDataModel {
  String data = "";

  JsDataModel({this.data = ""});

  JsDataModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data;
    return data;
  }
}

class DappModel {
  String id = "";
  String icon = "";
  String nameLang = "";

  DappModel(imageUrl, name) {
    icon = imageUrl;
    nameLang = name;
  }

  DappModel.fromJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == {}) {
      return;
    }
    if (jsonStr["data"] != null) {
      jsonStr = jsonStr["data"];
    }
    id = jsonStr["id"].toString();
    icon = jsonStr["icon"] ?? "";
    nameLang = jsonStr["nameLang"] ?? "";
  }

  // Map toJson() {
  //   Map map = Map();
  //   map["id"] = id;
  //   map["icon"] = icon;
  //   map["nameLang"] = nameLang;

  //   return map;
  // }
}
