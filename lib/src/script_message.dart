import 'dart:convert';

extension ScriptMessage on dynamic {
  /// 将消息解析为 JSON 格式的 Map
  Map<String, dynamic> get json {
    try {
      if (this is String) {
        // 如果消息是字符串，尝试解析为 JSON
        return jsonDecode(this as String) as Map<String, dynamic>;
      } else if (this is Map<String, dynamic>) {
        // 如果消息已经是 Map，直接返回
        return this as Map<String, dynamic>;
      }
    } catch (e) {
      // 捕获解析失败的情况
      print('Failed to parse JSON: $e');
    }
    return {};
  }
}
