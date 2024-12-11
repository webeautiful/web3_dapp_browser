import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Config {
  final EthereumConfig ethereum;
  // final SolanaConfig solana;
  // final AptosConfig aptos;
  final String appVersion;
  final bool autoConnect;

  Config({
    required this.ethereum,
    // required this.solana,
    // required this.aptos,
    this.appVersion = '0.0.1',
    this.autoConnect = true,
  });
}

class EthereumConfig {
  final String address;
  final int chainId;
  final String rpcUrl;

  EthereumConfig({
    required this.address,
    required this.chainId,
    required this.rpcUrl,
  });
}

class SolanaConfig {
  final String cluster;

  SolanaConfig({required this.cluster});
}

class AptosConfig {
  final String network;
  final String chainId;

  AptosConfig({required this.network, required this.chainId});
}

class TrustWeb3Provider {
  final Config config;
  final bool useOldVersion;
  String scriptHandlerName = "_tw_";

  TrustWeb3Provider({required this.config, this.useOldVersion = false}) {
    if (useOldVersion) {
      scriptHandlerName = 'OrangeHandler';
    }
  }

  // Inject provider asset file
  String providerJsAsset() {
    if (useOldVersion) {
      return 'packages/web3_dapp_browser/assets/js/provider.min.js';
    }
    if (Platform.isIOS) {
      return 'packages/web3_dapp_browser/assets/js/ios-web3-provider.min.js';
    } else if (Platform.isAndroid) {
      return 'packages/web3_dapp_browser/assets/js/android-web3-provider.min.js';
    }
    return '';
  }

  Future<String> _loadProviderJs() async {
    return await rootBundle.loadString(providerJsAsset());
  }

  /// Inject Provider Script
  Future<UserScript> get providerScript async {
    final source = await _loadProviderJs();
    return UserScript(
      source: source,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    );
  }

  /// Inject Script
  UserScript get injectScript {
    late String source;

    if (useOldVersion) {
      source = '''
        (function() {
          if(window.ethereum == null){
            var config = {
                ethereum: {
                    chainId: ${config.ethereum.chainId},
                    rpcUrl: "${config.ethereum.rpcUrl}",
                    address: "${config.ethereum.address}"
                },
                solana: {
                    cluster: "mainnet-beta",
                },
                isDebug: true
            };
            trustwallet.ethereum = new trustwallet.Provider(config);
            trustwallet.solana = new trustwallet.SolanaProvider(config);
            trustwallet.postMessage = (json) => {
                // window._tw_.postMessage(JSON.stringify(json));
                console.log('trustwallet.postMessage=>', json)
                if (window._tw_) {
                  window._tw_.postMessage(JSON.stringify(json));
                } else if(window.flutter_inappwebview.callHandler) {
                  // @params - eg. {id: 0, name: 'signMessage', object: { chainId: 56 }, network: 'BSC'}
                  window.flutter_inappwebview.callHandler('_tw_', json)
                }
            }
            window.ethereum = trustwallet.ethereum;
          }
        })();
        ''';
    } else {
      source = """
        (function() {
            const config = {
                ethereum: {
                    address: "${config.ethereum.address}",
                    chainId: ${config.ethereum.chainId},
                    rpcUrl: "${config.ethereum.rpcUrl}",
                    overwriteMetamask: false
                },
                // solana: {
                //     cluster: "{config.solana.cluster}",
                //     // @todo: remove this when mobile supports versioned transactions
                //     useLegacySign: true
                // },
                // aptos: {
                //     network: "{config.aptos.network}",
                //     chainId: "{config.aptos.chainId}"
                // }
            };

            const strategy = 'CALLBACK';

            try {
                const core = trustwallet.core(strategy, (params) => {
                     // Disabled methods
                    if (params.name === 'wallet_requestPermissions') {
                        core.sendResponse(params.id, null);
                        return;
                    }
                    if(window.flutter_inappwebview.callHandler) {
                      // @params - eg. {id: 0, name: 'signMessage', object: { chainId: 56 }, network: 'BSC'}
                      window.flutter_inappwebview.callHandler('$scriptHandlerName', params)
                    }
                });

                // Generate instances
                let ethereum = trustwallet.ethereum(config.ethereum);
                // const solana = trustwallet.solana(config.solana);
                // const cosmos = trustwallet.cosmos();
                // const aptos = trustwallet.aptos(config.aptos);
                // const ton = trustwallet.ton();

                const walletInfo = {
                  deviceInfo: {
                    platform: 'iphone',
                    appName: 'flutterwallet',
                    appVersion: "${config.appVersion}",
                    maxProtocolVersion: 2,
                    features: [
                      'SendTransaction',
                      {
                        name: 'SendTransaction',
                        maxMessages: 4,
                      },
                    ],
                  },
                  walletInfo: {
                    name: 'Trust',
                    image: 'https://assets-cdn.trustwallet.com/dapps/trust.logo.png',
                    about_url: 'https://trustwallet.com/about-us',
                  },
                  isWalletBrowser: ${config.autoConnect},
                };

                // const tonBridge = trustwallet.tonBridge(walletInfo, ton);

                // core.registerProviders([ethereum, solana, cosmos, aptos, ton].map(provider => {
                core.registerProviders([ethereum].map(provider => {
                  provider.sendResponse = core.sendResponse.bind(core);
                  provider.sendError = core.sendError.bind(core);
                  return provider;
                }));

                // window.trustwalletTon = { tonconnect: tonBridge, provider: ton };

                // Custom methods
                ethereum.emitChainChanged = (chainId) => {
                  ethereum.setChainId('0x' + parseInt(chainId || '1').toString(16));
                  ethereum.emit('chainChanged', ethereum.getChainId());
                  ethereum.emit('networkChanged', parseInt(chainId || '1'));
                };

                ethereum.setConfig = (config) => {
                  ethereum.setChainId('0x' + parseInt(config.ethereum.chainId || '1').toString(16));
                  ethereum.setAddress(config.ethereum.address);
                  if (config.ethereum.rpcUrl) {
                    ethereum.setRPCUrl(config.ethereum.rpcUrl);
                  }
                };
                // End custom methods

                // cosmos.mode = 'extension';
                // cosmos.providerNetwork = 'cosmos';
                // cosmos.isKeplr = true;
                // cosmos.version = "0.12.106";

                // cosmos.enable = (chainIds)  => {
                //   console.log(`==> enabled for \${chainIds}`);
                // };

                // Attach to window
                trustwallet.ethereum = ethereum;
                // trustwallet.solana = solana;
                // trustwallet.cosmos = cosmos;
                // trustwallet.TrustCosmos = trustwallet.cosmos;
                // trustwallet.aptos = aptos;
                // trustwallet.ton = ton;

                window.ethereum = trustwallet.ethereum;
                // window.keplr = trustwallet.cosmos;
                // window.aptos = trustwallet.aptos;
                // window.ton = trustwallet.ton;

                // const getDefaultCosmosProvider = (chainId) => {
                //   return trustwallet.cosmos.getOfflineSigner(chainId);
                // };

                // window.getOfflineSigner = getDefaultCosmosProvider;
                // window.getOfflineSignerOnlyAmino = getDefaultCosmosProvider;
                // window.getOfflineSignerAuto = getDefaultCosmosProvider;

                Object.assign(window.trustwallet, {
                  isTrust: true,
                  isTrustWallet: true,
                  request: ethereum.request.bind(ethereum),
                  send: ethereum.send.bind(ethereum),
                  on: (...params) => ethereum.on(...params),
                  off: (...params) => ethereum.off(...params),
                });

                const provider = ethereum;
                const proxyMethods = ['chainId', 'networkVersion', 'address', 'enable', 'send'];

                // Attach properties to trustwallet object (legacy props)
                const proxy = new Proxy(window.trustwallet, {
                  get(target, prop, receiver) {
                    if (proxyMethods.includes(prop)) {
                      switch (prop) {
                        case 'chainId':
                          return ethereum.getChainId.bind(provider);
                        case 'networkVersion':
                          return ethereum.getNetworkVersion.bind(provider);
                        case 'address':
                          return ethereum.getAddress.bind(provider);
                        case 'enable':
                          return ethereum.enable.bind(provider);
                        case 'send':
                          return ethereum.send.bind(provider);
                      }
                    }

                    return Reflect.get(target, prop, receiver);
                  },
                });

                window.trustwallet = proxy;
                window.trustWallet = proxy;

                const EIP6963Icon =
                'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNTgiIGhlaWdodD0iNjUiIHZpZXdCb3g9IjAgMCA1OCA2NSIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTAgOS4zODk0OUwyOC44OTA3IDBWNjUuMDA0MkM4LjI1NDUgNTYuMzM2OSAwIDM5LjcyNDggMCAzMC4zMzUzVjkuMzg5NDlaIiBmaWxsPSIjMDUwMEZGIi8+CjxwYXRoIGQ9Ik01Ny43ODIyIDkuMzg5NDlMMjguODkxNSAwVjY1LjAwNDJDNDkuNTI3NyA1Ni4zMzY5IDU3Ljc4MjIgMzkuNzI0OCA1Ny43ODIyIDMwLjMzNTNWOS4zODk0OVoiIGZpbGw9InVybCgjcGFpbnQwX2xpbmVhcl8yMjAxXzY5NDIpIi8+CjxkZWZzPgo8bGluZWFyR3JhZGllbnQgaWQ9InBhaW50MF9saW5lYXJfMjIwMV82OTQyIiB4MT0iNTEuMzYxNSIgeTE9Ii00LjE1MjkzIiB4Mj0iMjkuNTM4NCIgeTI9IjY0LjUxNDciIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KPHN0b3Agb2Zmc2V0PSIwLjAyMTEyIiBzdG9wLWNvbG9yPSIjMDAwMEZGIi8+CjxzdG9wIG9mZnNldD0iMC4wNzYyNDIzIiBzdG9wLWNvbG9yPSIjMDA5NEZGIi8+CjxzdG9wIG9mZnNldD0iMC4xNjMwODkiIHN0b3AtY29sb3I9IiM0OEZGOTEiLz4KPHN0b3Agb2Zmc2V0PSIwLjQyMDA0OSIgc3RvcC1jb2xvcj0iIzAwOTRGRiIvPgo8c3RvcCBvZmZzZXQ9IjAuNjgyODg2IiBzdG9wLWNvbG9yPSIjMDAzOEZGIi8+CjxzdG9wIG9mZnNldD0iMC45MDI0NjUiIHN0b3AtY29sb3I9IiMwNTAwRkYiLz4KPC9saW5lYXJHcmFkaWVudD4KPC9kZWZzPgo8L3N2Zz4K';

                const info = {
                  uuid: crypto.randomUUID(),
                  name: 'Trust Wallet',
                  icon: EIP6963Icon,
                  rdns: 'com.trustwallet.app',
                };

                const announceEvent = new CustomEvent('eip6963:announceProvider', {
                  detail: Object.freeze({ info, provider: ethereum }),
                });

                window.dispatchEvent(announceEvent);

                window.addEventListener('eip6963:requestProvider', () => {
                   window.dispatchEvent(announceEvent);
                });
            } catch (e) {
              console.error(e)
            }
        })();
        """;
    }
    return UserScript(
      source: source,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    );
  }
}

extension TrustWeb3ProviderExtension on TrustWeb3Provider {
  /// Ethereum TrustWeb3Provider Instant
  static TrustWeb3Provider createEthereum({
    required String address,
    required int chainId,
    required String rpcUrl,
  }) {
    return TrustWeb3Provider(
      config: Config(
        ethereum: EthereumConfig(
          address: address,
          chainId: chainId,
          rpcUrl: rpcUrl,
        ),
      ),
    );
  }
}
