/*
 * @Author: nlj 
 * @Date: 2023-01-07 10:09:02 
 * @Last Modified by: nlj
 * @Last Modified time: 2023-08-28 17:31:21
 */


 

import 'dart:convert';

class DappNameModel {
  String en_US_name = "";
  String zh_CN_name = "";

  String en_US_desc = "";
  String zh_CN_desc = "";


  DappNameModel();

  DappNameModel.fromJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == {}) {
      return;
    }
    if (jsonStr["data"] != null) {
      jsonStr = jsonStr["data"];
    }
    en_US_name = jsonStr["en_US"] ?? "";
    zh_CN_name = jsonStr["zh_CN"] ?? "";
    en_US_desc = jsonStr["en_US"] ?? "";
    zh_CN_desc = jsonStr["zh_CN"] ?? "";
  }

  Map toJson() {
    Map map = Map();
    map["en_US"] = en_US_name;
    map["zh_CN"] = zh_CN_name;
    map["en_US"] = en_US_desc;
    map["zh_CN"] = zh_CN_desc;

    return map;
  }
}

class DappModel {
  String id = "";
  String name = "";
  String icon = "";
  String nameLang = "";
  String address = "";
  String collect = "";// 收藏1,
  String history = "";// 历史1,
  String descriptionLang = "";
  String description = "";
  String typeNameLang = "";
  List chainName = [];

  bool isSelected = false;

  DappNameModel nameModel = DappNameModel();
  DappNameModel descModel = DappNameModel();

  DappModel();

  DappModel.fromJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == {}) {
      return;
    }
    if (jsonStr["data"] != null) {
      jsonStr = jsonStr["data"];
    }
    id = jsonStr["id"].toString();
    name = jsonStr["name"] ?? "";
    icon = jsonStr["icon"] ?? "";
    address = jsonStr["address"] ?? "";
    collect = jsonStr["collect"] ?? "";
    history = jsonStr["history"] ?? "";
    if (jsonStr["chainName"] is String) {
      chainName = jsonDecode(jsonStr["chainName"]);
    } else {
      chainName = jsonStr["chainName"] ?? [];
    }
    nameLang = jsonStr["nameLang"] ?? "";
    descriptionLang = jsonStr["descriptionLang"] ?? "";
    description = jsonStr["description"] ?? "";
    typeNameLang = jsonStr["typeNameLang"] ?? "";

    nameModel = DappNameModel.fromJson(jsonDecode(name));
    descModel = DappNameModel.fromJson(jsonDecode(description));
  }

  Map toJson() {
    Map map = Map();
    map["id"] = id;
    map["name"] = name;
    map["icon"] = icon;
    map["address"] = address;
    map["collect"] = collect;
    map["history"] = history;
    map["nameLang"] = nameLang;
    map["chainName"] = chainName;
    map["descriptionLang"] = descriptionLang;
    map["description"] = description;
    map["typeNameLang"] = typeNameLang;

    return map;
  }
}




// 测试
class MainNetworkItem {
  static String id = "id";
  static String columnUrl = "column_url";
  static String name = "name";
  static String icon = "icon";
  static String nameLang = "name_lang";
  static String descriptionLang = "description_lang";
  static String typeNameLang = "type_name_lang";
  static String columnKey = "column_key";
  static String columnLength = "column_length";
}

class MainNetworkModel {
  String id = "";
  String name = "";
  String chain = "";
  String icon = "";
  String nameLang = "";
  String descriptionLang = "";
  String typeNameLang = "";

  bool isSelected = false;

  MainNetworkModel(
      {this.id = "",
      this.name = "",
      this.chain = "",
      this.icon = "",
      this.nameLang = "",
      this.descriptionLang = "",
      this.typeNameLang = "",
      this.isSelected = false});

  MainNetworkModel.fromJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == {}) {
      return;
    }
    if (jsonStr["data"] != null) {
      jsonStr = jsonStr["data"];
    }
    id = jsonStr["id"].toString();
    name = jsonStr["name"] ?? "";
    chain = jsonStr["chain"] ?? "";
    icon = jsonStr["icon"] ?? "";
    nameLang = jsonStr["nameLang"] ?? "";
    descriptionLang = jsonStr["descriptionLang"] ?? "";
    typeNameLang = jsonStr["typeNameLang"] ?? "";
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = Map();
    map["id"] = id;
    map["name"] = name;
    map["icon"] = icon;
    map["nameLang"] = nameLang;
    map["descriptionLang"] = descriptionLang;
    map["typeNameLang"] = typeNameLang;

    return map;
  }

  Map<String, dynamic> toSqlJson() {
    Map<String, dynamic> map = Map();
    map["id"] = id;
    map["name"] = name;
    map["icon"] = icon;
    map["name_lang"] = nameLang;
    map["description_lang"] = descriptionLang;
    map["type_name_lang"] = typeNameLang;

    return map;
  }
}

class DappTokenModel {
  String id = "";
  String name = "";
  String icon = "";
  String nameLang = "";
  String descriptionLang = "";
  String typeNameLang = "";

  bool isSelected = false;

  DappTokenModel();

  DappTokenModel.fromJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == {}) {
      return;
    }
    if (jsonStr["data"] != null) {
      jsonStr = jsonStr["data"];
    }
    id = jsonStr["id"].toString();
    name = jsonStr["name"] ?? "";
    icon = jsonStr["icon"] ?? "";
    nameLang = jsonStr["nameLang"] ?? "";
    descriptionLang = jsonStr["descriptionLang"] ?? "";
    typeNameLang = jsonStr["typeNameLang"] ?? "";
  }

  Map toJson() {
    Map map = Map();
    map["id"] = id;
    map["name"] = name;
    map["icon"] = icon;
    map["nameLang"] = nameLang;
    map["descriptionLang"] = descriptionLang;
    map["typeNameLang"] = typeNameLang;

    return map;
  }
}


class JsCallbackModel {
  int id = 0;
  String name = "";
  Map<String, dynamic> object = {};
  String network = "";

  JsCallbackModel({this.id = 0, this.name= "", required this.object, this.network = ""});

  JsCallbackModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    object = json['object'];
    network = json['network'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['object'] = object;
    data['network'] = network;
    return data;
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

class JsAddEthereumChain {
  String chainId = "";

  JsAddEthereumChain({this.chainId =""});

  JsAddEthereumChain.fromJson(Map<String, dynamic> json) {
    chainId = json['chainId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['chainId'] = chainId;
    return data;
  }
}

class JsTransactionObject {
  String gas = "";
  String value = "";
  String from = "";
  String to = "";
  String data = "";

  JsTransactionObject({this.gas = "", this.value = "", this.from = "", this.to = "", this.data = ""});

  JsTransactionObject.fromJson(Map<String, dynamic> json) {
    gas = json['gas'];
    value = json['value'];
    from = json['from'];
    to = json['to'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gas'] = gas;
    data['value'] = value;
    data['from'] = from;
    data['to'] = to;
    data['data'] = data;
    return data;
  }
}