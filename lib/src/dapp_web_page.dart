import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import './token_helper.dart';
import './dapp_approve_view.dart';
import 'dapp_model.dart';
import 'dart:io';

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
      // nodeAddress- 节点地址
      required this.nodeAddress,
      // 账户地址
      required this.address,
      // 私钥
      required this.privateKey,
      // dapp模型用于在授权时展示
      required this.dappModel,
      // selectChainName
      required this.selectChainName})
      : super(key: key);

  String url = "";

  String nodeAddress = "";

  ValueChanged<int> onProgressChanged;

  ValueChanged<String> onConsoleMessage;

  DappWebController dappViewController;

  VoidCallback onLoadStop;

  String selectChainName;

  String address = "";

  String privateKey = "";

  DappModel dappModel;

  @override
  State<StatefulWidget> createState() {
    return DappWebPageSatae();
  }
}

class DappWebPageSatae extends State<DappWebPage> {
  String selectChainName = "";

  int cId = 0;

  int chainId = 56;

  static final _scriptHandlerName = '_tw_';

  late InAppWebViewController _controllerWebView;

  late String address;

  late JsCallbackModel jsData;

  @override
  void initState() {
    super.initState();
    addlistener();
  }

  // 监听
  addlistener() {
    widget.dappViewController.addListener(() async {
      // ignore: unrelated_type_equality_checks
      if (widget.dappViewController.dappWebOperate == DappWebOperate.reload) {
        _controllerWebView.reload();
      }

      // ignore: unrelated_type_equality_checks
      if (widget.dappViewController.dappWebOperate == DappWebOperate.goback) {
        _controllerWebView.goBack();
      }

      // ignore: unrelated_type_equality_checks
      if (widget.dappViewController.dappWebOperate == DappWebOperate.runjs) {
        try {
          // 获取当前钱包
          final setAddress =
              "window.ethereum.setAddress(\"${widget.address.toLowerCase()}\");";
          address = widget.address.toLowerCase();
          String callback =
              "window.ethereum.sendResponse(${jsData.id}, [\"$address\"])";
          await _sendCustomResponse(_controllerWebView, setAddress);
          await _sendCustomResponse(_controllerWebView, callback);
          final initString = _addChain(
              chainId, widget.nodeAddress, widget.address.toLowerCase(), true);

          print("授权登录: $initString");
          await _sendCustomResponse(_controllerWebView, initString);
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
    //
    // await _controllerWebView.injectJavascriptFileFromAsset(
    //     assetFilePath:
    //         'packages/web3_dapp_browser/assets/js/eruda-3.2.1.min.js');
    await _controllerWebView.injectJavascriptFileFromAsset(
        assetFilePath: 'packages/web3_dapp_browser/assets/js/test.js');
    // await _controllerWebView.injectJavascriptFileFromAsset(
    //     assetFilePath: 'packages/web3_dapp_browser/assets/js/provider.min.js');

    late String web3ProviderAsset;
    if (Platform.isIOS) {
      web3ProviderAsset =
          'packages/web3_dapp_browser/assets/js/ios-web3-provider.min.js';
    } else {
      web3ProviderAsset =
          'packages/web3_dapp_browser/assets/js/android-web3-provider.min.js';
    }
    await _controllerWebView.injectJavascriptFileFromAsset(
        assetFilePath: web3ProviderAsset);

    String initJs = reInit
        ? _loadReInt(chainId, widget.nodeAddress, widget.address.toLowerCase())
        : _loadInitJs(chainId, widget.nodeAddress);
    await _controllerWebView.evaluateJavascript(source: initJs);
    if (controller.hasJavaScriptHandler(handlerName: _scriptHandlerName)) {
      return;
    }
    _controllerWebView.addJavaScriptHandler(
        handlerName: _scriptHandlerName,
        callback: (callback) async {
          jsData = JsCallbackModel.fromJson(callback[0]);
          debugPrint("callBack1: $callback");
          switch (jsData.name) {
            case "signTransaction":
              {
                _sendResult(controller, "ethereum", "signedData", jsData.id);
                break;
              }
            case "signPersonalMessage":
              {
                try {
                  JsDataModel data = JsDataModel.fromJson(jsData.object);
                  var signedData = await TokenHelper.signPersonalMessage(
                      widget.privateKey, data.data);
                  _sendResult(controller, "ethereum", signedData, jsData.id);
                } catch (e) {
                  print(e);
                }
                break;
              }
            case "signMessage":
              {
                break;
              }
            case "signTypedMessage":
              {
                break;
              }
            case "requestAccounts":
              {
                showScreenView(
                    context,
                    390,
                    DappApproveView(
                        dappdismiss: (value) {
                          if (value == 1) {
                            widget.dappViewController.requestAccounts(chainId);
                          }
                        },
                        model: widget.dappModel));
                break;
              }
            case "switchEthereumChain":
              {
                try {
                  _sendResult(controller, "ethereum",
                      "https://rpc.ankr.com/eth", jsData.id);
                  chainId = jsData.objModel.chainId;
                  final initString = _addChain(jsData.objModel.chainId,
                      "https://rpc.ankr.com/eth", address, false);
                  _sendCustomResponse(controller, initString);
                } catch (e) {
                  print(e);
                }
                break;
              }
          }
        });
  }

  String _addChain(int chainId, String rpcUrl, String address, bool isDebug) {
    // String source = '''window.ethereum.setNetwork({
    String source = '''window.ethereum.setConfig({
          ethereum:{
            chainId: $chainId,
            rpcUrl: "$rpcUrl",
            address: "$address",
            isDebug: $isDebug
            }
          }
        )
        ''';
    return source;
  }

  Future<void> _sendResult(InAppWebViewController controller, String network,
      String message, int methodId) {
    String script = "window.$network.sendResponse($methodId, \"$message\")";
    debugPrint(script);
    return controller
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) => debugPrint(error.toString()));
  }

  Future<void> _sendCustomResponse(
      InAppWebViewController controller, String response) {
    return controller
        .evaluateJavascript(source: response)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) => debugPrint(error.toString()));
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
                      window.flutter_inappwebview.callHandler('$_scriptHandlerName', params)
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
                window.trustWallet = proxy;

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
                window.flutter_inappwebview.callHandler('$_scriptHandlerName', json)
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

  Future showScreenView(BuildContext context, double height, Widget child,
      {double radius = 12.0,
      bool autoDismiss = false,
      String title = "",
      bool isScrollControlled = true}) async {
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
}

class DappWebController extends ChangeNotifier {
  /// Creates a page controller.

  DappWebController({this.dappWebOperate = DappWebOperate.goback});
  // 请求web的方法
  DappWebOperate dappWebOperate = DappWebOperate.reload;

  String runjsUrl = "";

  int cid = 56;

  void reload() async {
    dappWebOperate = DappWebOperate.reload;
    notifyListeners();
  }

  void goback() async {
    dappWebOperate = DappWebOperate.goback;
    notifyListeners();
  }

  void requestAccounts(int chainId) async {
    cid = chainId;
    dappWebOperate = DappWebOperate.runjs;
    notifyListeners();
  }
}
