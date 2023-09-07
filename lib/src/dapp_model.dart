/*
 * @Author: nlj 
 * @Date: 2023-01-07 10:09:02 
 * @Last Modified by: nlj
 * @Last Modified time: 2023-09-06 18:19:26
 */


class JsCallbackModel {
  int id = 0;
  String name = "";
  Map<String, dynamic> object = {};
  String network = "";

  // JsCallbackModel({this.id = 0, this.name= "", required this.object, this.network = ""});

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
