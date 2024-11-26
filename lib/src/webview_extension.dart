import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web3_dapp_browser/src/provider_network.dart';
import 'package:web3_dapp_browser/src/trust_web3_provider.dart'
    as trust_web3_provider;

/// 提供对 WebView 的类型包装
class TypeWrapper<T> {
  final T value;

  TypeWrapper(this.value);
}

extension WebViewWrapper on InAppWebViewController {
  TypeWrapper<InAppWebViewController> get tw => TypeWrapper(this);
}

extension WebViewFunctions on TypeWrapper<InAppWebViewController> {
  /// 设置网络和地址
  Future<void> set(ProviderNetwork network, String address) async {
    final script =
        'trustwallet.${network.name}.setAddress("${address.toLowerCase()}");';
    await _valuateJavascript(source: script);
  }

  /// 设置配置信息
  Future<void> setConfig(trust_web3_provider.Config config) async {
    final script = """
    var config = {
        ethereum: {
            address: "${config.ethereum.address}",
            chainId: ${config.ethereum.chainId},
            rpcUrl: "${config.ethereum.rpcUrl}"
        }
    };
    ethereum.setConfig(config);
    """;
    await _valuateJavascript(source: script);
  }

  /// 触发链切换事件
  Future<void> emitChange(int chainId) async {
    final hexChainId = '0x${chainId.toRadixString(16)}';
    final script = 'trustwallet.ethereum.emitChainChanged("$hexChainId");';
    await _valuateJavascript(source: script);
  }

  /// 发送错误响应
  Future<void> sendError(ProviderNetwork network, String error, int id) async {
    final script = 'trustwallet.${network.name}.sendError($id, "$error");';
    await _valuateJavascript(source: script);
  }

  /// 发送单个结果响应
  Future<void> sendResponse(
      ProviderNetwork network, String result, int requestId) async {
    final script =
        "trustwallet.${network.name}.sendResponse($requestId, '$result');";
    await _valuateJavascript(source: script);
  }

  /// 发送空结果响应
  Future<void> sendNullResponse(ProviderNetwork network, int id) async {
    final script = "trustwallet.${network.name}.sendResponse($id, null);";
    await _valuateJavascript(source: script);
  }

  /// 发送数组结果响应
  Future<void> sendArrayResponse(
      ProviderNetwork network, List<String> results, int id) async {
    final encodedArray = results.map((result) => '"$result"').join(',');
    final script =
        "trustwallet.${network.name}.sendResponse($id, [$encodedArray]);";
    await _valuateJavascript(source: script);
  }

  /// 移除脚本消息处理器（在 Flutter 中不需要手动调用此方法）
  Future<void> removeScriptHandler(String handlerName) async {
    // Flutter 中无需显式移除 handler，但可以通过 API 来更新或重置。
    // 这里如果有特定需求，可以用类似逻辑清理资源。
    print('Handler $handlerName removed (no-op in flutter)');
  }

  Future<void> _valuateJavascript({required String source}) {
    return value
        .evaluateJavascript(source: source)
        .then((value) => print(value))
        .onError((error, stackTrace) => print(error.toString()));
  }
}
