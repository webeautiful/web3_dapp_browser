import 'dart:convert';
import 'dart:io';
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
  DappWebPage({
    Key? key,
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
    // 私钥
    required this.privateKey,
    // dapp模型用于在授权时展示
    required this.dappModel,
    // selectChainName
    required this.selectChainName,
    required this.config,
  }) : super(key: key);

  String url = "";

  ValueChanged<int> onProgressChanged;

  ValueChanged<String> onConsoleMessage;

  DappWebController dappViewController;

  VoidCallback onLoadStop;

  String selectChainName;

  String address = "";

  String privateKey = "";
  Config config;

  DappModel dappModel;

  @override
  State<StatefulWidget> createState() {
    return DappWebPageSatae();
  }
}

class DappWebPageSatae extends State<DappWebPage> {
  late TrustWeb3Provider _provider;

  String selectChainName = "";

  late InAppWebViewController _controllerWebView;

  int chainId = 56;
  late String address;

  late JsCallbackModel jsData;

  @override
  void initState() {
    super.initState();
    _provider = TrustWeb3Provider(config: widget.config);
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

      if (widget.dappViewController.dappWebOperate == DappWebOperate.runjs) {
        try {
          // fetch current wallet
          final network = ProviderNetworkExtension.fromString(jsData.network);
          await _controllerWebView.tw.set(network, address);
          await _controllerWebView.tw
              .sendArrayResponse(network, [address], jsData.id);
          await _controllerWebView.tw.setConfig(
            Config(
              ethereum: widget.config.ethereum,
            ),
          );
          print("授权登录");
        } catch (e) {
          debugPrint(e.toString());
        }
      }
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
      onLoadStop: (InAppWebViewController controller, uri) {
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
    await _controllerWebView.injectJavascriptFileFromAsset(
        assetFilePath: 'packages/web3_dapp_browser/assets/js/custom.js');

    // String initJs = reInit
    //     ? _loadReInt(chainId, widget.config.ethereum.rpcUrl,
    //         widget.address.toLowerCase())
    //     : _loadInitJs(chainId, widget.config.ethereum.rpcUrl);
    await _controllerWebView.evaluateJavascript(
        source: _provider.injectScript.source);
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
                handleRequestAccounts(json);
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

  String _loadInitJsForIOS(int chainId, String rpcUrl, String address) {
    String source = """
        (function() {
            const config = {
                ethereum: {
                    address: "$address",
                    chainId: $chainId,
                    rpcUrl: "$rpcUrl"
                },
                // solana: {
                //     cluster: "config.solana.cluster",
                //     // @todo: remove this when mobile supports versioned transactions
                //     useLegacySign: true
                // },
                // aptos: {
                //     network: "config.aptos.network",
                //     chainId: "config.aptos.chainId"
                // }
            };

            const strategy = 'CALLBACK';

            try {
                const core = trustwallet.core(strategy, (params) => {
                     // Disabled methods
                    if (params.name === 'wallet_requestPermissions') {
                        core.sendResponse(params.id, null);
                        return;
                    }
                    if(window.flutter_inappwebview.callHandler) {
                      // @params - eg. {id: 0, name: 'signMessage', object: { chainId: 56 }, network: 'BSC'}
                      window.flutter_inappwebview.callHandler('_tw_', params)
                    }
                });

                // Generate instances
                const ethereum = trustwallet.ethereum(config.ethereum);
                // const solana = trustwallet.solana(config.solana);
                // const cosmos = trustwallet.cosmos();
                // const aptos = trustwallet.aptos(config.aptos);
                // const ton = trustwallet.ton();

                const walletInfo = {
                  deviceInfo: {
                    platform: 'iphone',
                    appName: 'flutterwallet',
                    appVersion: "0.0.1",
                    maxProtocolVersion: 2,
                    features: [
                      'SendTransaction',
                      {
                        name: 'SendTransaction',
                        maxMessages: 4,
                      },
                    ],
                  },
                  walletInfo: {
                    name: 'Trust',
                    image: 'https://assets-cdn.trustwallet.com/dapps/trust.logo.png',
                    about_url: 'https://trustwallet.com/about-us',
                  },
                  isWalletBrowser: true,
                };

                // const tonBridge = trustwallet.tonBridge(walletInfo, ton);

                // core.registerProviders([ethereum, solana, cosmos, aptos, ton].map(provider => {
                core.registerProviders([ethereum].map(provider => {
                  provider.sendResponse = core.sendResponse.bind(core);
                  provider.sendError = core.sendError.bind(core);
                  return provider;
                }));

                // window.trustwalletTon = { tonconnect: tonBridge, provider: ton };

                // Custom methods
                ethereum.emitChainChanged = (chainId) => {
                  ethereum.setChainId('0x' + parseInt(chainId || '1').toString(16));
                  ethereum.emit('chainChanged', ethereum.getChainId());
                  ethereum.emit('networkChanged', parseInt(chainId || '1'));
                };

                ethereum.setConfig = (config) => {
                  ethereum.setChainId('0x' + parseInt(config.ethereum.chainId || '1').toString(16));
                  ethereum.setAddress(config.ethereum.address);
                  if (config.ethereum.rpcUrl) {
                    ethereum.setRPCUrl(config.ethereum.rpcUrl);
                  }
                };
                // End custom methods

                // cosmos.mode = 'extension';
                // cosmos.providerNetwork = 'cosmos';
                // cosmos.isKeplr = true;
                // cosmos.version = "0.12.106";

                // cosmos.enable = (chainIds)  => {
                //   console.log(`==> enabled for \${chainIds}`);
                // };

                // Attach to window
                trustwallet.ethereum = ethereum;
                // trustwallet.solana = solana;
                // trustwallet.cosmos = cosmos;
                // trustwallet.TrustCosmos = trustwallet.cosmos;
                // trustwallet.aptos = aptos;
                // trustwallet.ton = ton;

                window.ethereum = trustwallet.ethereum;
                // window.keplr = trustwallet.cosmos;
                // window.aptos = trustwallet.aptos;
                // window.ton = trustwallet.ton;

                // const getDefaultCosmosProvider = (chainId) => {
                //   return trustwallet.cosmos.getOfflineSigner(chainId);
                // };

                // window.getOfflineSigner = getDefaultCosmosProvider;
                // window.getOfflineSignerOnlyAmino = getDefaultCosmosProvider;
                // window.getOfflineSignerAuto = getDefaultCosmosProvider;

                Object.assign(window.trustwallet, {
                  isTrust: true,
                  isTrustWallet: true,
                  request: ethereum.request.bind(ethereum),
                  send: ethereum.send.bind(ethereum),
                  on: (...params) => ethereum.on(...params),
                  off: (...params) => ethereum.off(...params),
                });

                const provider = ethereum;
                const proxyMethods = ['chainId', 'networkVersion', 'address', 'enable', 'send'];

                // Attach properties to trustwallet object (legacy props)
                const proxy = new Proxy(window.trustwallet, {
                  get(target, prop, receiver) {
                    if (proxyMethods.includes(prop)) {
                      switch (prop) {
                        case 'chainId':
                          return ethereum.getChainId.bind(provider);
                        case 'networkVersion':
                          return ethereum.getNetworkVersion.bind(provider);
                        case 'address':
                          return ethereum.getAddress.bind(provider);
                        case 'enable':
                          return ethereum.enable.bind(provider);
                        case 'send':
                          return ethereum.send.bind(provider);
                      }
                    }

                    return Reflect.get(target, prop, receiver);
                  },
                });

                window.trustwallet = proxy;

                const EIP6963Icon =
                'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNTgiIGhlaWdodD0iNjUiIHZpZXdCb3g9IjAgMCA1OCA2NSIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTAgOS4zODk0OUwyOC44OTA3IDBWNjUuMDA0MkM4LjI1NDUgNTYuMzM2OSAwIDM5LjcyNDggMCAzMC4zMzUzVjkuMzg5NDlaIiBmaWxsPSIjMDUwMEZGIi8+CjxwYXRoIGQ9Ik01Ny43ODIyIDkuMzg5NDlMMjguODkxNSAwVjY1LjAwNDJDNDkuNTI3NyA1Ni4zMzY5IDU3Ljc4MjIgMzkuNzI0OCA1Ny43ODIyIDMwLjMzNTNWOS4zODk0OVoiIGZpbGw9InVybCgjcGFpbnQwX2xpbmVhcl8yMjAxXzY5NDIpIi8+CjxkZWZzPgo8bGluZWFyR3JhZGllbnQgaWQ9InBhaW50MF9saW5lYXJfMjIwMV82OTQyIiB4MT0iNTEuMzYxNSIgeTE9Ii00LjE1MjkzIiB4Mj0iMjkuNTM4NCIgeTI9IjY0LjUxNDciIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KPHN0b3Agb2Zmc2V0PSIwLjAyMTEyIiBzdG9wLWNvbG9yPSIjMDAwMEZGIi8+CjxzdG9wIG9mZnNldD0iMC4wNzYyNDIzIiBzdG9wLWNvbG9yPSIjMDA5NEZGIi8+CjxzdG9wIG9mZnNldD0iMC4xNjMwODkiIHN0b3AtY29sb3I9IiM0OEZGOTEiLz4KPHN0b3Agb2Zmc2V0PSIwLjQyMDA0OSIgc3RvcC1jb2xvcj0iIzAwOTRGRiIvPgo8c3RvcCBvZmZzZXQ9IjAuNjgyODg2IiBzdG9wLWNvbG9yPSIjMDAzOEZGIi8+CjxzdG9wIG9mZnNldD0iMC45MDI0NjUiIHN0b3AtY29sb3I9IiMwNTAwRkYiLz4KPC9saW5lYXJHcmFkaWVudD4KPC9kZWZzPgo8L3N2Zz4K';

                const info = {
                  uuid: crypto.randomUUID(),
                  name: 'Trust Wallet',
                  icon: EIP6963Icon,
                  rdns: 'com.trustwallet.app',
                };

                const announceEvent = new CustomEvent('eip6963:announceProvider', {
                  detail: Object.freeze({ info, provider: ethereum }),
                });

                window.dispatchEvent(announceEvent);

                window.addEventListener('eip6963:requestProvider', () => {
                   window.dispatchEvent(announceEvent);
                });
            } catch (e) {
              console.error(e)
            }
        })();
        """;
    return source;
  }

  // ignore: unused_element
  String _loadInitJsForAndroid(int chainId, String rpcUrl) {
    String source = """
        (function() {
            var config = {
                ethereum: {
                    chainId: $chainId,
                    rpcUrl: "$rpcUrl"
                },
                // solana: {
                //     cluster: "mainnet-beta",
                // },
                isDebug: true
            };
            trustwallet.ethereum = new trustwallet.Provider(config);
            // trustwallet.solana = new trustwallet.SolanaProvider(config);
            trustwallet.postMessage = (json) => {
                // @json - eg. {id: 0, name: 'signMessage', object: { chainId: 56 }, network: 'BSC'}
                window.flutter_inappwebview.callHandler('_tw_', json)
            }
            window.ethereum = trustwallet.ethereum;
        })();
    """;
    return source;
  }

  String _loadReInt(int chainId, String rpcUrl, String address) {
    if (Platform.isIOS) {
      return _loadInitJsForIOS(chainId, rpcUrl, address);
    } else if (Platform.isAndroid) {
      return _loadInitJsForIOS(chainId, rpcUrl, address);
      // return _loadInitJsForAndroid(chainId, rpcUrl);
    } else {
      return '';
    }
  }

  String _loadInitJs(int chainId, String rpcUrl) {
    if (Platform.isIOS) {
      return _loadInitJsForIOS(chainId, rpcUrl, '');
    } else if (Platform.isAndroid) {
      return _loadInitJsForIOS(chainId, rpcUrl, '');
      // return _loadInitJsForAndroid(chainId, rpcUrl);
    } else {
      return '';
    }
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

  void handleSignTransaction(JsCallbackModel jsData) {
    // _sendResult(controller, "ethereum", "signedData", jsData.id);
    _controllerWebView.tw
        .sendResponse(ProviderNetwork.ethereum, 'signedData', jsData.id);
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
      var signedData =
          await TokenHelper.signPersonalMessage(widget.privateKey, data.data);
      // _sendResult(controller, "ethereum", signedData, jsData.id);
      _controllerWebView.tw
          .sendResponse(ProviderNetwork.ethereum, signedData, jsData.id);
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

  void handleRequestAccounts(Map<String, dynamic> json) {
    showScreenView(
        context,
        390,
        DappApproveView(
          dappdismiss: (value) {
            if (value == 1) {
              widget.dappViewController.requestAccounts();
            }
          },
          model: widget.dappModel,
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
    try {
      _controllerWebView.tw.sendResponse(
          ProviderNetwork.ethereum, 'https://rpc.ankr.com/eth', jsData.id);
      // final initString = _addChain(jsData.objModel.chainId,
      //     "https://rpc.ankr.com/eth", address, false);
      // _sendCustomResponse(controller, initString);
      _controllerWebView.tw.setConfig(
        Config(
          ethereum: EthereumConfig(
            address: address,
            chainId: jsData.objModel.chainId,
            rpcUrl: 'https://rpc.ankr.com/eth',
          ),
        ),
      );
    } catch (e) {
      print(e);
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
