import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web3_dapp_browser/src/provider_network.dart';
import 'package:web3_dapp_browser/web3_dapp_browser.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // For signing-related methods

class DAppWebViewController extends StatefulWidget {
  @override
  State<DAppWebViewController> createState() => _DAppWebViewControllerState();
}

class _DAppWebViewControllerState extends State<DAppWebViewController> {
  late TextEditingController urlFieldController;
  late InAppWebViewController webViewController;

  String get homepage => "https://pancakeswap.finance/";

  // static final wallet = HDWallet(strength: 128, passphrase: ""); // 示例占位

  TrustWeb3Provider current = TrustWeb3Provider(
    config: Config(
      ethereum: ethereumConfigs[0],
    ),
  );

  Map<int, TrustWeb3Provider> providers = {
    for (var config in ethereumConfigs)
      config.chainId: TrustWeb3Provider(config: Config(ethereum: config)),
  };

  static final List<EthereumConfig> ethereumConfigs = [
    EthereumConfig(
      address: "0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f",
      chainId: 1,
      rpcUrl: "https://cloudflare-eth.com",
    ),
    EthereumConfig(
      address: "0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f",
      chainId: 10,
      rpcUrl: "https://mainnet.optimism.io",
    ),
    EthereumConfig(
      address: "0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f",
      chainId: 56,
      rpcUrl: "https://bsc-dataseed4.ninicoin.io",
    ),
    EthereumConfig(
      address: "0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f",
      chainId: 137,
      rpcUrl: "https://polygon-rpc.com",
    ),
    EthereumConfig(
      address: "0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f",
      chainId: 250,
      rpcUrl: "https://rpc.ftm.tools",
    ),
    EthereumConfig(
      address: "0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f",
      chainId: 42161,
      rpcUrl: "https://arb1.arbitrum.io/rpc",
    ),
  ];

  List<String> cosmosChains = [
    "osmosis-1",
    "cosmoshub",
    "cosmoshub-4",
    "kava_2222-10",
    "evmos_9001-2",
  ];

  String currentCosmosChain = "osmosis-1";

  @override
  void initState() {
    super.initState();
    urlFieldController = TextEditingController(text: homepage);
  }

  Future<void> _initWeb3() async {
    final providerScript = await current.providerScript;
    final injectScript = current.injectScript;

    webViewController.addUserScript(userScript: providerScript);
    webViewController.addUserScript(userScript: injectScript);
  }

  void navigateTo(String url) {
    webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  String get cosmosCoin {
    switch (currentCosmosChain) {
      case "osmosis-1":
        return "osmosis";
      case "cosmoshub":
      case "cosmoshub-4":
        return "cosmos";
      case "kava_2222-10":
        return "kava";
      case "evmos_9001-2":
        return "nativeEvmos";
      default:
        throw Exception("No coin found for the current config");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: urlFieldController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: "Enter URL"),
          onSubmitted: (url) => navigateTo(url),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(homepage)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                allowsInlineMediaPlayback: true,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  urlFieldController.text = url.toString();
                });
              },
              onLoadStop: (controller, url) async {
                _initWeb3();
                setState(() {
                  urlFieldController.text = url.toString();
                });
              },
              onConsoleMessage: (controller, consoleMessage) {
                print("Console log: ${consoleMessage.message}");
              },
              onReceivedError: (controller, request, error) {
                print("Error loading ${request.url}: ${error.description}");
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                print(
                    "HTTP error loading ${request.url}: ${errorResponse.statusCode}");
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    urlFieldController.dispose();
    super.dispose();
  }
}

class JsbridgeCallbackHandler {
  /// Setup WebView to handle DApp-related functionality
  Future<void> setupWebView(InAppWebViewController webViewController) async {
    webViewController.addJavaScriptHandler(
      handlerName: 'TrustWeb3Provider',
      callback: (args) {
        if (args.isNotEmpty && args[0] is Map<String, dynamic>) {
          final json = args[0] as Map<String, dynamic>;
          final method = extractMethod(json);
          switch (method) {
            case DAppMethod.signRawTransaction:
              handleSignRawTransaction(json);
              break;
            case DAppMethod.signTransaction:
              handleSignTransaction(json);
              break;
            case DAppMethod.signMessage:
              handleSignMessage(json);
              break;
            case DAppMethod.signTypedMessage:
              handleSignTypedMessage(json);
              break;
            case DAppMethod.signPersonalMessage:
              handleSignPersonalMessage(json);
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
              handleSwitchChain(json);
              break;
            default:
              print('Unhandled method: $method');
          }
        }
      },
    );
  }

  // -------------------------
  // DApp Method Handlers
  // -------------------------

  void handleSignRawTransaction(Map<String, dynamic> json) {
    print('Handling signRawTransaction: $json');
    // Add implementation
  }

  void handleSignTransaction(Map<String, dynamic> json) {
    print('Handling signTransaction: $json');
    // Add implementation
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

  void handleSignPersonalMessage(Map<String, dynamic> json) {
    print('Handling signPersonalMessage: $json');
    // Add implementation
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
    print('Handling requestAccounts: $json');
    // Add implementation
  }

  void handleWatchAsset(Map<String, dynamic> json) {
    print('Handling watchAsset: $json');
    // Add implementation
  }

  void handleAddEthereumChain(Map<String, dynamic> json) {
    print('Handling addEthereumChain: $json');
    // Add implementation
  }

  void handleSwitchChain(Map<String, dynamic> json) {
    print('Handling switchChain: $json');
    // Add implementation
  }

  // -------------------------
  // JSON Extraction Helpers
  // -------------------------

  DAppMethod? extractMethod(Map<String, dynamic> json) {
    final method = json['method'] as String?;
    return DAppMethod.values.firstWhere(
      (e) => e.name == method,
    );
  }

  ProviderNetwork? extractNetwork(Map<String, dynamic> json) {
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

// -------------------------
// Enums for Method Types
// -------------------------

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
