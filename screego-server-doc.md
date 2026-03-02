# screego serverについて

https://screego.net/#/

### install

https://screego.net/#/install
- TLSが必要なのでリバプロを使用するか、Screego内でTLSを有効化するか

### Docker

- 基本的にマルチアーキテクチャ対応の Docker イメージを起動するだけでScreegoは動く
- デフォルトポートは5050だが、`SCREEGO_EXTERNAL_IP=`を指定することで対応可能。

### 特徴

- 複数ユーザーの画面共有
- WebRTCによる安全な転送
- 低遅延 / 高解像度
- Docker / 単一バイナリによるシンプルなインストール
- 統合TURNサーバーについてはNATトラバーサルを参照してください

### NATトラバーサル

通常、ピア接続はFirewallなどの影響で直接通信できません。
しかし、WebRTCはICEというピア接続を支援するフレームワークを使い、STUNサーバとTURNサーバによってピア接続を実現する。

**WebRTC**
- https://webrtc.org/?hl=ja
- 音声・映像などをリアルタイムにやりとりするための標準規格+実装などの技術セットのこと
- 実装部分はICEプロトコルやSTUN・TURNといった技術によって実現される。

**STUN**
- Session Traversal Utilities for NAT (STUN)
- 外部から見た自PCのIPアドレスを返してくれる。
  - STUNによって返されるIPとPCから見えるIPが異なる場合、NATが使用されているということが分かる。
  - ここで分かった自PCの外部から見たIPはP2Pの相手に送信される。

STUNはほとんどのケースで機能しますが、Symmetric NATなどより厳格なNATでは機能しない場合があります。その場合、TURNが使用されます。

**TURN**
- Traversal Using Relays around NAT (TURN)
- TURNはSymmetric NATを回避するために使用される
- TURNは、すべてのデータをTURNサーバー経由で中継することで実現する。

ICE
- TURNサーバは通信を中継するため負荷が高くなりがちでサーバーコストなどもかかる。そのためWebRTCではできる限り、STUNに寄せてそれでもダメならTURNを使うといったバックアップ形式を取っている。
- この仕組みをプロトコルとして実装しているのがICEである。

**Symmetric NAT ?**
- 対称型NAT
- 送信元（内部IPとポート）が同じでも、通信相手（宛先）が変わるたびに異なる外部ポート番号を割り当てるセキュリティ強度の高いNAT方式。
  - つまりSTUNのように自身の外から見たIPを送信先に送る方法では、宛先ごとに変わるために自身のポートが分からない、といったことが起こりうる可能性が想定できる。

**より詳細な説明**
- https://zenn.dev/daddy_yukio/books/43790f0b74d317/viewer/5c4618




