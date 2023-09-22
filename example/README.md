# example

web3_dapp_browser support dapp load

## Getting Started

```dart
web3_dapp_browser: ^1.0.1
```

## Usage

引入方式

```dart
import 'package:web3_dapp_browser/web3_dapp_browser.dart';
```


web3_dapp_browser 具体实现


声明

```dart
// 控制器
late DappWebController _dappwebController;

// dapp对象
DappModel dapp = DappModel("https://img2.baidu.com/it/u=4094580296,2373583296&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=500", "BSC");


```


实现

```dart

//  UI加载
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
                    address: "0xc9e90f889***********e01cfa1ac",
                    // url: "https://blur.io",
                    url: "https://uniswap.org",
                    privateKey: "4fa2ce0741a6b031eb************1841d39481",
                    nodeAddress: "",
                    dappModel: dapp,
                    requestAccounts: (data) {
                      _dappwebController.requestAccounts();
                    },
                    selectChainName: "BSC")),
          ],
      ),
    );

```



## Additional information

实现效果


<table>
<tr>
<td valign="center"><img src="https://github.com/JamesBondMine/lj_loadding_empty/blob/main/lib/assets/images/load.png?raw=true"> 
</td>
<td valign="center"><img src="https://github.com/JamesBondMine/lj_loadding_empty/blob/main/lib/assets/images/load.png?raw=true"> 
</td>
</tr>
</table>