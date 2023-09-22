/*
 * @Author: nlj 
 * @Date: 2023-01-07 10:09:02 
 * @Last Modified by: nlj
 * @Last Modified time: 2023-09-06 18:19:26
 */


class JsCallbackObjectModel {

  int chainId = 0x1;

  JsCallbackObjectModel.fromJson(Map<String, dynamic> json) {
    if(!json['chainId']) return;
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

  DappModel(imageUrl,name){
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
