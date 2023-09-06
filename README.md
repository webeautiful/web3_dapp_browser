

web3_dapp_browser dapp browser

## Features

web3_dapp_browser can load dapp url

## Getting started

```dart
web3_dapp_browser: ^1.0.0
```

## Usage

引入方式

```dart
import 'package:web3_dapp_browser/web3_dapp_browser.dart';
```


loadding具体实现

```dart
 Scaffold(
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
```


 却省图具体实现

```dart
SizedBox(height: 400,width: 300,child: EmptyView()),
```


## Additional information

web3_dapp_browser support load dapp url


approve效果

<table>
<tr>
<td valign="center"><img src="https://github.com/JamesBondMine/web3_dapp_browser/blob/main/lib/assets/images/1.png?raw=true"> 
</td>
<!-- <td valign="center"><img src="https://github.com/JamesBondMine/lj_loadding_empty/blob/main/lib/assets/images/load.png?raw=true"> 
</td> -->
</tr>
</table>

loaded效果

<table>
<tr>
<td valign="center"><img src="https://github.com/JamesBondMine/web3_dapp_browser/blob/main/lib/assets/images/2.png?raw=true"> 
</td>
<!-- <td valign="center"><img src="https://github.com/JamesBondMine/lj_loadding_empty/blob/main/lib/assets/images/empty.png?raw=true"> 
</td> -->
</tr>
</table>
