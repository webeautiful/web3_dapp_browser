import 'package:flutter/material.dart';
import 'package:web3_dapp_browser/web3_dapp_browser.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'web3_dapp_browser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'web3_dapp_browser'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DappWebController _dappwebController;

  @override
  void initState() {
    super.initState();
    _dappwebController = DappWebController();
  }

  @override
  Widget build(BuildContext context) {
    
    DappModel dapp = DappModel("https://img2.baidu.com/it/u=4094580296,2373583296&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=500", "BSC");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: DappWebPage(
                    dappViewController: _dappwebController,
                    onProgressChanged: (progress) {},
                    onConsoleMessage: (log) {
                      // print(log);
                    },
                    onLoadStop: () {},
                    address: "0xc9e90f88932827c32065a5e0ddbf077e01cfa1ac",
                    // url: "https://blur.io",
                    url: "https://uniswap.org",
                    privateKey: "4fa2ce0741a6b031eb67abb8855a965c2dc3be2a9febc3c9bde3bc1841d39481",
                    nodeAddress: "",
                    dappModel: dapp,
                    requestAccounts: (data) {
                      _dappwebController.requestAccounts();
                    },
                    selectChainName: "BSC")),
          ],
      ),
    );
  }
}
