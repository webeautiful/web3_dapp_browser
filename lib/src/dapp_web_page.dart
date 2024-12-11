import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web3_dapp_browser/src/dapp_method.dart';
import 'package:web3_dapp_browser/src/provider_network.dart';
import 'package:web3_dapp_browser/src/trust_web3_provider.dart';
import 'package:web3_dapp_browser/src/webview_extension.dart';
import './token_helper.dart';
import './dapp_approve_view.dart';
import 'dapp_model.dart';
import 'package:crypto/crypto.dart';

enum DappWebOperate { reload, goback, runjs }

// ignore: must_be_immutable
class DappWebPage extends StatefulWidget {
  DappWebPage(
      {Key? key,
      // dapp地址
      this.url = "",
      // dapp 加载进度
      required this.onProgressChanged,
      // 消息
      required this.onConsoleMessage,
      // onLoadStop
      required this.onLoadStop,
      // Controller
      required this.dappViewController,
      required this.onSignPermit,
      required this.config,
      required this.providers})
      : super(key: key);

  String url = "";

  ValueChanged<int> onProgressChanged;

  ValueChanged<String> onConsoleMessage;

  DappWebController dappViewController;

  VoidCallback onLoadStop;

  String address = "";

  Future<String> Function() onSignPermit;
  Config config;
  Map<int, TrustWeb3Provider> providers;

  @override
  State<StatefulWidget> createState() {
    return DappWebPageSatae();
  }
}

class DappWebPageSatae extends State<DappWebPage> {
  late TrustWeb3Provider _provider;

  late InAppWebViewController _controllerWebView;

  int chainId = 0;
  late String address;

  late JsCallbackModel jsData;

  late DappModel dappModel = DappModel(
      'https://0xzx.com/wp-content/uploads/2021/05/20210530-19.jpg', 'Init');

  @override
  void initState() {
    super.initState();
    _provider = TrustWeb3Provider(config: widget.config, useOldVersion: true);
    address = widget.config.ethereum.address.toLowerCase();
    chainId = widget.config.ethereum.chainId;
    addlistener();
  }

  // 监听
  addlistener() {
    widget.dappViewController.addListener(() async {
      if (widget.dappViewController.dappWebOperate == DappWebOperate.reload) {
        _controllerWebView.reload();
      }

      if (widget.dappViewController.dappWebOperate == DappWebOperate.goback) {
        _controllerWebView.goBack();
      }

      if (widget.dappViewController.dappWebOperate == DappWebOperate.runjs) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return _webAppContent();
  }

  Widget _webAppContent() {
    WebUri requestUri = WebUri(widget.url);
    return InAppWebView(
      initialUrlRequest: URLRequest(url: requestUri),
      initialSettings: InAppWebViewSettings(
        // useShouldOverrideUrlLoading: true, //加载url拦截功能
        useShouldInterceptAjaxRequest: true, //ajax请求拦截
        useOnLoadResource: true, //资源加载回调
        allowFileAccessFromFileURLs: true, //资源加载
        mediaPlaybackRequiresUserGesture: false, //多媒体控制
        useHybridComposition: true, //支持HybridComposition
        useShouldInterceptRequest: true, //请求加载链接，可以用于实现Web离线包
        allowsInlineMediaPlayback: true,
      ),
      onWebViewCreated: (InAppWebViewController webcontroller) {
        _controllerWebView = webcontroller;
      },
      onLoadStop: (InAppWebViewController controller, url) async {
        if (url == null) return;
        // String baseUrl = url.origin;
        // 获取 favicon 的相对路径
        // String? relativeIconPath =
        //     await controller.evaluateJavascript(source: """
        //       (() => {
        //         let icon = document.querySelector("link[rel*='icon']");
        //         return icon ? icon.getAttribute('href') : null;
        //       })();
        //       """);
        // 解析为绝对路径
        // String? absoluteIconUrl;
        // if (relativeIconPath != null) {
        //   absoluteIconUrl =
        //       Uri.parse(baseUrl).resolve(relativeIconPath).toString();
        // }
        // final faviconUrl = absoluteIconUrl ??
        //     'https://0xzx.com/wp-content/uploads/2021/05/20210530-19.jpg';
        // 更新页面标题
        // String? title = await controller.evaluateJavascript(
        //     source: "document.querySelector('title')?.innerText");
        // dappModel = DappModel(faviconUrl, title);
        _initWeb3(controller, true);
        widget.onLoadStop();
      },
      onConsoleMessage: (controller, url) async {
        print("网页在进行打印: ${url.messageLevel}: ${url.message}");
        // _dapptouchEvent(url.message);
        widget.onConsoleMessage(url.message);
      },
      onLoadStart: (c, url) async {
        _initWeb3(c, false);
      },
      onReceivedError: (controller, request, error) {
        print("网页在进行打印ERROR: ${error.description}");
      },
      onProgressChanged: (InAppWebViewController c, int i) {
        _initWeb3(c, true);
        widget.onProgressChanged(i);
      },
      shouldInterceptRequest: (controller, request) async {
        if (request.url.scheme == "http") {
          print("Intercepted insecure HTTP request: ${request.url}");
          // 可选择拦截或跳转到 HTTPS
        }
        return null; // 默认继续加载
      },
    );
  }

  _initWeb3(InAppWebViewController controller, bool reInit) async {
    // inject provider
    await _controllerWebView.injectJavascriptFileFromAsset(
        assetFilePath: _provider.providerJsAsset());
    // await _controllerWebView.addUserScript(
    //     userScript: await _provider.providerScript);
    // await _controllerWebView.injectJavascriptFileFromAsset(
    //     assetFilePath: 'packages/web3_dapp_browser/assets/js/custom.js');

    // Future.delayed(Duration(seconds: 1), () {
    _controllerWebView.evaluateJavascript(
        source: _provider.injectScript.source);
    // });
    // await _controllerWebView.addUserScript(userScript: _provider.injectScript);
    if (controller.hasJavaScriptHandler(
        handlerName: _provider.scriptHandlerName)) {
      return;
    }
    _controllerWebView.addJavaScriptHandler(
        handlerName: _provider.scriptHandlerName,
        callback: (args) async {
          debugPrint("callBack1: $args");
          if (args.isNotEmpty && args[0] is Map<String, dynamic>) {
            final json = args[0] as Map<String, dynamic>;
            jsData = JsCallbackModel.fromJson(json);
            final method = extractMethod(json);
            switch (method) {
              case DAppMethod.signRawTransaction:
                handleSignRawTransaction(json);
                break;
              case DAppMethod.signTransaction:
                handleSignTransaction(jsData);
                break;
              case DAppMethod.signMessage:
                handleSignMessage(json);
                break;
              case DAppMethod.signTypedMessage:
                handleSignTypedMessage(json);
                break;
              case DAppMethod.signPersonalMessage:
                await handleSignPersonalMessage(json);
                break;
              case DAppMethod.sendTransaction:
                handleSendTransaction(json);
                break;
              case DAppMethod.ecRecover:
                handleEcRecover(json);
                break;
              case DAppMethod.requestAccounts:
                handleRequestAccounts(jsData);
                break;
              case DAppMethod.watchAsset:
                handleWatchAsset(json);
                break;
              case DAppMethod.addEthereumChain:
                handleAddEthereumChain(json);
                break;
              case DAppMethod.switchEthereumChain:
              case DAppMethod.switchChain:
                handleSwitchChain(jsData);
                break;
              default:
                print('Unhandled method: $method');
            }
          }
        });
  }

  // 减号
  Widget _dismissView(
    BuildContext context,
  ) {
    return InkWell(
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(bottom: 0),
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  Future showScreenView(
    BuildContext context,
    double height,
    Widget child, {
    double radius = 12.0,
    bool autoDismiss = false,
    String title = "",
    bool isScrollControlled = true,
  }) async {
    return await showModalBottomSheet<void>(
        context: context,
        enableDrag: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
        ),
        elevation: 20,
        builder: (BuildContext context) {
          return SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                autoDismiss ? _dismissView(context) : Container(),
                title.isEmpty
                    ? Container()
                    : Text(
                        title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.w600),
                      ),
                Expanded(child: child)
              ],
            ),
          );
        });
  }

  // -------------------------
  // DApp Method Handlers
  // -------------------------

  void handleSignRawTransaction(Map<String, dynamic> json) {
    print('Handling signRawTransaction: $json');
    // Add implementation
  }

  Future<void> handleSignTransaction(JsCallbackModel jsData) async {
    // _sendResult(controller, "ethereum", "signedData", jsData.id);
    final privateKey = await widget.onSignPermit();
    // TODO: implement signEthTransaction
    var signedData = await TokenHelper.signEthTransaction(privateKey, '');
    final network = ProviderNetworkExtension.fromString(jsData.network);
    _controllerWebView.tw.sendResponse(network, signedData, jsData.id);
  }

  void handleSignMessage(Map<String, dynamic> json) {
    final data = extractMessage(json);
    if (data != null) {
      final signedData = signMessage(data);
      print('Signed Message: $signedData');
    }
  }

  void handleSignTypedMessage(Map<String, dynamic> json) {
    print('Handling signTypedMessage: $json');
    // Add implementation
  }

  Future<void> handleSignPersonalMessage(Map<String, dynamic> json) async {
    try {
      JsDataModel data = JsDataModel.fromJson(jsData.object);
      final privateKey = await widget.onSignPermit();
      var signedData =
          await TokenHelper.signPersonalMessage(privateKey, data.data);
      final network = ProviderNetworkExtension.fromString(jsData.network);
      _controllerWebView.tw.sendResponse(network, signedData, jsData.id);
    } catch (e) {
      print(e);
    }
  }

  void handleSendTransaction(Map<String, dynamic> json) {
    print('Handling sendTransaction: $json');
    // Add implementation
  }

  void handleEcRecover(Map<String, dynamic> json) {
    print('Handling ecRecover: $json');
    // Add implementation
  }

  void handleRequestAccounts(JsCallbackModel jsData) {
    showScreenView(
        context,
        390,
        DappApproveView(
          dappdismiss: (value) async {
            final network = ProviderNetworkExtension.fromString(jsData.network);
            if (value == 1) {
              // widget.dappViewController.requestAccounts();
              try {
                // fetch current wallet
                if (_provider.useOldVersion) {
                  await _controllerWebView.tw.set(network, address);
                  await _controllerWebView.tw
                      .sendArrayResponse(network, [address], jsData.id);
                  await _controllerWebView.tw.setOldConfig(
                    Config(
                      ethereum: widget.config.ethereum,
                    ),
                  );
                } else {
                  await _controllerWebView.tw.set(network, address);
                  await _controllerWebView.tw
                      .sendArrayResponse(network, [address], jsData.id);
                }
                print("授权登录");
              } catch (e) {
                debugPrint(e.toString());
              }
            } else {
              _controllerWebView.tw
                  .sendError(network, 'Request Canceled!', jsData.id);
            }
          },
          model: dappModel,
        ));
  }

  void handleWatchAsset(Map<String, dynamic> json) {
    print('Handling watchAsset: $json');
    // Add implementation
  }

  void handleAddEthereumChain(Map<String, dynamic> json) {
    print('Handling addEthereumChain: $json');
    // Add implementation
  }

  void handleSwitchChain(JsCallbackModel jsData) {
    var chainID = jsData.objModel.chainId;
    var network = ProviderNetworkExtension.fromString(jsData.network);
    if (widget.providers[chainID] == null) {
      _controllerWebView.tw.sendError(network, '不支持该网络', jsData.id);
      return;
    }
    var current = widget.providers[chainID]!;
    _controllerWebView.tw
        .sendResponse(network, current.config.ethereum.rpcUrl, jsData.id);
    if (_provider.useOldVersion) {
      _controllerWebView.tw.setOldConfig(current.config);
    } else {
      _controllerWebView.tw.setConfig(current.config);
    }
  }

  // -------------------------
  // JSON Extraction Helpers
  // -------------------------

  DAppMethod? extractMethod(Map<String, dynamic> json) {
    final method = json['name'] as String?;
    return DAppMethod.values.firstWhere(
      (e) => e.name == method,
    );
  }

  ProviderNetwork extractNetwork(Map<String, dynamic> json) {
    final network = json['network'] as String?;
    return ProviderNetworkExtension.fromString(network);
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

  // Add more JSON extraction helpers as needed...

  // -------------------------
  // Utility Methods
  // -------------------------

  Uint8List signMessage(Uint8List data, {bool addPrefix = true}) {
    if (addPrefix) {
      final prefix =
          utf8.encode("\u{19}Ethereum Signed Message:\n${data.length}");
      data = Uint8List.fromList(prefix + data);
    }
    final hash = sha256.convert(data).bytes;
    // Here, implement your signing logic (e.g., using a private key)
    return Uint8List.fromList(hash);
  }

  String? ecRecover(Uint8List signature, Uint8List message) {
    // Implement ECDSA recovery logic
    return null;
  }

  // -------------------------
  // Alert Helper
  // -------------------------

  void alert({required String title, required String message}) {
    print('ALERT: $title - $message');
  }
}

class DappWebController extends ChangeNotifier {
  /// Creates a page controller.

  DappWebController({this.dappWebOperate = DappWebOperate.goback});
  // request web method
  DappWebOperate dappWebOperate = DappWebOperate.reload;
  late ProviderNetwork network;

  void reload() async {
    dappWebOperate = DappWebOperate.reload;
    notifyListeners();
  }

  void goback() async {
    dappWebOperate = DappWebOperate.goback;
    notifyListeners();
  }

  void requestAccounts() async {
    dappWebOperate = DappWebOperate.runjs;
    notifyListeners();
  }
}
