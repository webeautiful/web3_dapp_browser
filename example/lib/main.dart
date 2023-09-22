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
    
    DappModel dapp = DappModel("https://0xzx.com/wp-content/uploads/2021/05/20210530-19.jpg", "UniSwap");
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
                    address: "0x******************a1ac",
                    url: "https://uniswap.org",
                    privateKey: "4fa2ce0741a6b0**************************9bde3bc1841d39481",
                    nodeAddress: "https://rpc.ankr.com/bsc",
                    dappModel: dapp,
                    selectChainName: "BSC")),
          ],
      ),
    );
  }
}
