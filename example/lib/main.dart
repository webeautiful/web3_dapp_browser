import 'package:flutter/material.dart';
import 'package:web3_dapp_browser/web3_dapp_browser.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'web3_dapp_browser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DappBrowserView(
        title: 'web3_dapp_browser',
      ),
    );
  }
}

class DappBrowserView extends StatefulWidget {
  const DappBrowserView({super.key, required this.title});

  final String title;

  @override
  State<DappBrowserView> createState() => _DappBrowserState();
}

class _DappBrowserState extends State<DappBrowserView> {
  late DappWebController _dappwebController;
  late final List<EthereumConfig> ethereumConfigs;

  @override
  void initState() {
    super.initState();
    _dappwebController = DappWebController();
    ethereumConfigs = [
      EthereumConfig(
        address: "0x1b5D1b47c415E79B41Fb08B7eCC0C552ea15fA8c",
        chainId: 56,
        rpcUrl: "https://bsc-dataseed1.binance.org",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    DappModel dapp = DappModel(
        "https://0xzx.com/wp-content/uploads/2021/05/20210530-19.jpg",
        "UniSwap");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: DappWebPage(
              // url: "http://192.168.8.20:8000/test.html?v=0.7",
              // url: "https://www.baidu.com",
              // url: "https://app.uniswap.org/",
              // url: "https://www.clickspro.io/#/en",
              url: "https://pancakeswap.finance/",
              dappViewController: _dappwebController,
              selectChainName: "BSC",
              config: Config(
                ethereum: ethereumConfigs[0],
              ),
              onProgressChanged: (progress) {},
              onConsoleMessage: (log) {
                // print(log);
              },
              onLoadStop: () {},
              privateKey:
                  "a404cb9eedb4985df6a21c156a5ca4e19ab3580fefbaf64c4a26da46c2df1df8",
              dappModel: dapp,
            ),
          ),
        ],
      ),
    );
  }
}
