import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

class TokenHelper {
  static Future<String> signPersonalMessage(
      String privateKey, String data) async {
    try {
      EthPrivateKey credentials = EthPrivateKey.fromHex(privateKey);
      Uint8List message =
          credentials.signPersonalMessageToUint8List(hexToBytes(data));
      String result = bytesToHex(message, include0x: true);
      return result;
    } catch (e) {
      return "";
    }
  }

  static Future<String> signEthTransaction(
      String privateKey, String data) async {
    try {
      EthPrivateKey credentials = EthPrivateKey.fromHex(privateKey);
      Uint8List message =
          credentials.signPersonalMessageToUint8List(hexToBytes(data));
      String result = bytesToHex(message, include0x: true);
      return result;
    } catch (e) {
      return "";
    }
  }
}
