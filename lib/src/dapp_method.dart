enum DAppMethod {
  signRawTransaction,
  signTransaction,
  signMessage,
  signTypedMessage,
  signPersonalMessage,
  sendTransaction,
  ecRecover,
  requestAccounts,
  watchAsset,
  addEthereumChain,
  switchEthereumChain, // legacy compatible
  switchChain,
}

extension DAppMethodExtension on DAppMethod {
  /// 获取枚举的字符串值
  String get rawValue => toString().split('.').last;

  /// 从字符串值解析为枚举
  static DAppMethod? fromRawValue(String value) {
    for (var method in DAppMethod.values) {
      if (method.rawValue == value) {
        return method;
      }
    }
    return null; // 返回 null 如果未找到匹配值
  }

  /// 获取所有枚举值的字符串列表
  static List<String> allRawValues() {
    return DAppMethod.values.map((method) => method.rawValue).toList();
  }
}
