# example

web3_dapp_browser support dapp load

## Getting Started

```dart
web3_dapp_browser: ^1.0.2
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
DappModel dapp = DappModel("https://0xzx.com/wp-content/uploads/2021/05/20210530-19.jpg", "UniSwap");


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
                    address: "0xc9e90f8893*************",
                    url: "https://uniswap.org",
                    privateKey: "4fa2ce0741a6b031eb67abb885***********",
                    nodeAddress: "https://rpc.ankr.com/bsc",
                    dappModel: dapp,
                    selectChainName: "BSC")),
          ],
      ),
    );

```



## Additional information

实现效果


<table>
<tr>
<td valign="center"><img src="https://github.com/JamesBondMine/web3_dapp_browser/blob/main/lib/assets/images/3.png?raw=true"> 
</td>
<td valign="center"><img src="https://github.com/JamesBondMine/web3_dapp_browser/blob/main/lib/assets/images/4.png?raw=true"> 
</td>
</tr>
</table>

实现效果

<table>
<tr>
<td valign="center"><img src="https://github.com/JamesBondMine/web3_dapp_browser/blob/main/lib/assets/images/5.png?raw=true"> 
</td>
<td valign="center"><img src="https://github.com/JamesBondMine/web3_dapp_browser/blob/main/lib/assets/images/6.png?raw=true"> 
</td>
</tr>
</table>
