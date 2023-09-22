
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import './token_helper.dart';
import './dapp_approve_view.dart';
import 'dapp_model.dart';

enum DappWebOperate {
  reload,
  goback,
  runjs
}

// ignore: must_be_immutable
class DappWebPage extends StatefulWidget  {

  DappWebPage({Key? key, 
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
  // 授权登录的方法
  required this.requestAccounts, 
  // selectChainName
  required this.selectChainName}):super(key: key);




  

  String url = "";

  String nodeAddress = "";

  ValueChanged<int> onProgressChanged;

  ValueChanged<String> onConsoleMessage;

  DappWebController dappViewController;

  VoidCallback onLoadStop;

  ValueChanged<JsCallbackModel> requestAccounts;

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
          final setAddress = "window.ethereum.setAddress(\"${widget.address.toLowerCase()}\");";
          address = widget.address.toLowerCase();
          String callback =
              "window.ethereum.sendResponse(${jsData.id}, [\"$address\"])";
          await _sendCustomResponse(_controllerWebView, setAddress);
          await _sendCustomResponse(_controllerWebView, callback);
          final initString = _addChain(chainId,widget.nodeAddress,widget.address.toLowerCase(),true);
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
    Uri requestUri = Uri.parse(widget.url);
    return InAppWebView(
      initialUrlRequest: URLRequest(url: requestUri),
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
        print("网页在进行打印ERROR: $message");
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
        assetFilePath: 'packages/web3_dapp_browser/assets/js/provider.min.js');

    String initJs = reInit
        ? _loadReInt(chainId, widget.nodeAddress, widget.address.toLowerCase())
        : _loadInitJs(chainId, widget.nodeAddress);
    await _controllerWebView.evaluateJavascript(source: initJs);
    if (controller.javaScriptHandlersMap["OrangeHandler"] != null) {
      return;
    }
     _controllerWebView.addJavaScriptHandler(
          handlerName: "OrangeHandler",
          callback: (callback) async {
            jsData = JsCallbackModel.fromJson(callback[0]);
            debugPrint("callBack1: $callback");
            switch (jsData.name) {
              case "signTransaction":{
                _sendResult(controller, "ethereum", "signedData", jsData.id);
                break;
              }
              case "signPersonalMessage":
                {
                  try {
                    JsDataModel data = JsDataModel.fromJson(jsData.object);
                    var signedData = await TokenHelper.signPersonalMessage(widget.privateKey, data.data);
                     _sendResult(controller, "ethereum", signedData, jsData.id);
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
                showScreenView(context, 390, DappApproveView(dappdismiss: (value) {
                  if (value==1) {
                    widget.requestAccounts(jsData);
                  }
                }, model: widget.dappModel));
                break;
              }
             case "switchEthereumChain":{
              try {
                  _sendResult(controller, "ethereum", widget.nodeAddress, jsData.id);
                  //
                  final initString = _addChain(chainId,widget.nodeAddress, address, false);
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
      {double radius = 12.0, bool autoDismiss = false, String title = "", bool isScrollControlled = true}) async {
    return await showModalBottomSheet<Null>(
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
                    title.isEmpty ? Container() : Text(title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: const Color(0xFF333333), fontWeight: FontWeight.w600),),
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
