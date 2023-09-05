import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:wallet_uu/database/token_helper.dart';
import 'package:wallet_uu/ui/dapp/page/dapp_net_wallet_select_page.dart';
import 'package:wallet_uu/ui/swap/controller/swap_controller.dart';
import 'package:wallet_uu/ui/swap/model/swap_model.dart';
import 'package:wallet_uu/ui/swap/model/token_service.dart';
import 'package:wallet_uu/ui/wallet/controller/token_controller.dart';
import 'package:wallet_uu/ui/dapp/model/dapp_model.dart';


enum DappWebOperate {
  reload,
  goback,
  runjs
}

// ignore: must_be_immutable
class DappWebPage extends StatefulWidget  {

  DappWebPage({Key key, 
  this.url, 
  this.onProgressChanged, 
  this.onConsoleMessage, 
  this.onLoadStop, 
  this.dappViewController, 
  this.requestAccounts, 
  this.selectChainName}):super(key: key);

  String url ;

  ValueChanged<int> onProgressChanged;

  ValueChanged<String> onConsoleMessage;

  DappWebController dappViewController;

  VoidCallback onLoadStop;

  ValueChanged<JsCallbackModel> requestAccounts;

  String selectChainName;
  
  @override
  State<StatefulWidget> createState() {
    return DappWebPageSatae();
  }
}


class DappWebPageSatae extends State<DappWebPage> {

    String selectChainName;
    
    int cId = 0;
    
    InAppWebViewController _controllerWebView;
  
    // 所有链
    List<SwapModel> smodelList = [];

    // 所有钱包
    List<SwapTokenModel> tokenList = [];

    // 当前钱包
    SwapTokenModel token;

    SwapModel smodel;

    DappSelectModel dappSelectModel;

    String address;

    JsCallbackModel jsData;


    @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectChainName = SwapController.to.readCurrentChain();
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
          final setAddress = "window.ethereum.setAddress(\"${token.address.toLowerCase()}\");";
          address = token.address.toLowerCase();
          String callback =
              "window.ethereum.sendResponse(${jsData.id}, [\"$address\"])";
          await _sendCustomResponse(_controllerWebView, setAddress);
          await _sendCustomResponse(_controllerWebView, callback);
          final initString = _addChain(int.tryParse(smodel.chainId),smodel.nodeAddress,token.address.toLowerCase(),true);
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
  
  /**
   * 
   * dapp浏览器
   * 目前仅支持: 登录、个人签名登录  切换链
   * 可用flutter_injected_web3: ^1.0.1插件代替
   *
   *   */    
  Widget _webAppContent() {
    
    return InAppWebView(
      initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true, //加载url拦截功能
          useShouldInterceptAjaxRequest: true, //ajax请求拦截
          useOnLoadResource: true, //资源加载回调
          allowFileAccessFromFileURLs: true, //资源加载
          mediaPlaybackRequiresUserGesture: false, //多媒体控制
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true, //支持HybridComposition
          useShouldInterceptRequest: true, //请求加载链接，可以用于实现Web离线包
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ),
      ),
      onWebViewCreated: (InAppWebViewController webcontroller) {
        _controllerWebView = webcontroller;
      },
      onLoadStop: (InAppWebViewController controller, uri) {
        // _initWeb3(_controllerWebView, true);
        // _dappLaunchApproveEvent();
        _initWeb3(controller, true);
        widget.onLoadStop();
        
      },
      onConsoleMessage: (controller, url) async {
        print("网页在进行打印: ${url.message}");
        // _dapptouchEvent(url.message);
        widget.onConsoleMessage(url.message);
      },
      onLoadStart: (c, url) async {
        _initWeb3(c, false);
      },
      onLoadError: (c, url, code, message) {
        print("\n==========================\n加载错误:\n");
        print(c);
        print("错误地址: " + url.toString());
        print("错误码: " + code.toString());
        print("错误信息: " + message);
        print("\n==========================\n");
      },
      onProgressChanged: (InAppWebViewController c, int i) {
        _initWeb3(c, true);
         widget.onProgressChanged(i);
      },
    );
  }

  _initWeb3(InAppWebViewController controller, bool reInit) async {

    // 
    await _controllerWebView.injectJavascriptFileFromAsset(
        assetFilePath: 'assets/dapp/provider.min.js');

    if (dappSelectModel != null) {
      token = dappSelectModel.swapTokenModel;
      smodel = dappSelectModel.swapModel;
    } else {
      smodelList = await SwapController.to.loadTokenListData();
      smodel = smodelList.firstWhereOrNull(
          (element) => element.chainName == selectChainName);
    }

     // 当前钱包
        tokenList =
            await SwapController.to.getChainWalletList(widget.selectChainName);
        token = tokenList.first;

    String initJs = reInit
        ? _loadReInt(int.tryParse(smodel.chainId), smodel.nodeAddress, token.address.toLowerCase())
        : _loadInitJs(int.tryParse(smodel.chainId), smodel.nodeAddress);
    await _controllerWebView.evaluateJavascript(source: initJs);
    if (controller.javaScriptHandlersMap["OrangeHandler"] != null) {
      return;
    }
    // return;
     _controllerWebView.addJavaScriptHandler(
          handlerName: "OrangeHandler",
          callback: (callback) async {
            jsData = JsCallbackModel.fromJson(callback[0]);

            debugPrint("callBack1: $callback");
            switch (jsData.name) {
              case "signTransaction":{
                final data = JsTransactionObject.fromJson(jsData.object ?? {});
                _sendResult(controller, "ethereum", "signedData", jsData.id ?? 0);
                break;
              }
              case "signPersonalMessage":
                {
                  try {
                    JsDataModel data = JsDataModel.fromJson(jsData.object ?? {});
                    var signedData = await TokenHelper.signPersonalMessage(token.privateKey, data.data);
                     _sendResult(controller, "ethereum", signedData, jsData.id ?? 0);
                  } catch (e) {
                    print(e);
                  }
                  break;
                }
                case "signMessage":{
                break;
              }
              case "signTypedMessage":{
                break;
              }
              case "requestAccounts":{
                widget.requestAccounts(jsData);
                break;
              }
             case "switchEthereumChain":{
              try {
                  final data = JsAddEthereumChain.fromJson(jsData.object ?? {});
                  int chainId = int.tryParse(data.chainId);
                  smodel = smodelList.firstWhereOrNull((element) => element.chainId == chainId.toString());
                  _sendResult(controller, "ethereum", smodel.nodeAddress, jsData.id ?? 0);
                  //
                  final initString = _addChain(chainId,smodel.nodeAddress, address, false);
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
    String source = '''
        window.ethereum.setNetwork({
          ethereum:{
            chainId: $chainId,
            rpcUrl: "$rpcUrl",
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

  String _loadReInt(int chainId, String rpcUrl, String address) {
    String source = '''
        (function() {
          if(window.ethereum == null){
            var config = {                
                ethereum: {
                    chainId: $chainId,
                    rpcUrl: "$rpcUrl",
                    address: "$address"
                },
                solana: {
                    cluster: "mainnet-beta",
                },
                isDebug: true
            };
            trustwallet.ethereum = new trustwallet.Provider(config);
            trustwallet.solana = new trustwallet.SolanaProvider(config);
            trustwallet.postMessage = (json) => {
                window._tw_.postMessage(JSON.stringify(json));
            }
            window.ethereum = trustwallet.ethereum;
          }
        })();
        ''';
    return source;
  }


  String _loadInitJs(int chainId, String rpcUrl) {
    String source = '''
        (function() {
            var config = {                
                ethereum: {
                    chainId: $chainId,
                    rpcUrl: "$rpcUrl"
                },
                solana: {
                    cluster: "mainnet-beta",
                },
                isDebug: true
            };
            trustwallet.ethereum = new trustwallet.Provider(config);
            trustwallet.solana = new trustwallet.SolanaProvider(config);
            trustwallet.postMessage = (json) => {
                window._tw_.postMessage(JSON.stringify(json));
            }
            window.ethereum = trustwallet.ethereum;
        })();
        ''';
    return source;
  }
}



class DappWebController extends ChangeNotifier {
  /// Creates a page controller.

  DappWebController({this.dappWebOperate = DappWebOperate.goback}): assert(dappWebOperate != null);
  // 请求web的方法
  DappWebOperate dappWebOperate;

  String runjsUrl;


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
