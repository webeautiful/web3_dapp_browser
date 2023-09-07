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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;

  late DappWebController _dappwebController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _dappwebController = DappWebController();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    onConsoleMessage: (log) {},
                    onLoadStop: () {},
                    address: "https://blur.io",
                    url: "https://blur.io",
                    privateKey: "",
                    nodeAddress: "",
                    requestAccounts: (data) {},
                    selectChainName: "ETH")),
          ],
      ),
    );
  }
}
