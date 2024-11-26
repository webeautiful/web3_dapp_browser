// Provider 网络枚举
enum ProviderNetwork { ethereum, solana, cosmos, aptos, ton, unknown }

extension ProviderNetworkExtension on ProviderNetwork {
  static ProviderNetwork fromString(String? network) {
    if (network == null) return ProviderNetwork.unknown;
    switch (network.toLowerCase()) {
      case 'ethereum':
        return ProviderNetwork.ethereum;
      case 'solana':
        return ProviderNetwork.solana;
      default:
        return ProviderNetwork.unknown;
    }
  }
}
