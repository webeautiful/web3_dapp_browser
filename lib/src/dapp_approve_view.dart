/*
 * @Author: nlj 
 * @Date: 2023-01-07 10:09:02 
 * @Last Modified by: nlj
 * @Last Modified time: 2023-09-05 16:17:38
 */

import 'package:flutter/material.dart';
import 'dapp_model.dart';

class DappApproveView extends StatefulWidget {
  const DappApproveView(
      {Key? key, required this.dappdismiss, required this.model})
      : super(key: key);

  final ValueChanged<int> dappdismiss;

  final DappModel model;

  @override
  State<DappApproveView> createState() => DappApproveViewState();
}

class DappApproveViewState extends State<DappApproveView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [_dismissView(), _headerView()],
          ),
        ],
      ),
    );
  }

  // 头部
  Widget _headerView() {
    return SizedBox(
        child: Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Text(
            "申请授权",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          margin:
              const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
          child: ClipOval(
              child: widget.model.icon.isEmpty
                  ? SizedBox(
                      width: 40,
                      height: 40,
                    )
                  : Image.network(
                      widget.model.icon,
                      width: 50,
                      height: 50,
                      fit: BoxFit.fill,
                    )),
        ),
        Text(
          widget.model.nameLang,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        Container(
          alignment: Alignment.center,
          margin:
              const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
          child: Text(
            "正在申请访问你的钱包地址,你确认将钱包地址公开给此网站吗?",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: const Color(0xFF333333), height: 1.5),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 5 / 12,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.purple.withAlpha(50)),
              child: TextButton(
                  onPressed: () {
                    widget.dappdismiss(0);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "拒绝",
                    style: TextStyle(color: Colors.purple),
                  )),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 5 / 12,
              decoration: BoxDecoration(
                  color: Colors.purple, borderRadius: BorderRadius.circular(8)),
              child: TextButton(
                  onPressed: () {
                    widget.dappdismiss(1);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "确定",
                    style: const TextStyle(color: Colors.white),
                  )),
            ),
          ],
        )
      ],
    ));
  }

  // 减号
  Widget _dismissView() {
    return InkWell(
      child: Container(
        height: 30,
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        child: Container(
          width: 40,
          height: 2,
          color: const Color(0xFF999999),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}
