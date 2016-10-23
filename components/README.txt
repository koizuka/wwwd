このモジュール[components]のビルド方法
2001-04-28 戀塚 koizuka@koizuka.jp

Delphi/C++Builderのメニュー上で
[コンポーネント(C)]メニューから[コンポーネントのインストール(I)]を選ぶ
[新規パッケージに追加]タブを選ぶ
ユニットファイル名(U)の右の[参照(B)]を押し、Delphiユニット(*.pas)を
選んで、このフォルダのすべてのpasファイルを一度に選択、開く(O)する

追加ダイアログに戻るので、パッケージファイル名欄に新規の名前を付ける
私はこのフォルダの下にCB4やDelphi4などのフォルダを掘って、そこに
koizuka.dpkやkoizuka.bpkというファイル名で作っています。

パッケージの説明は適当に入力してください。

これでOKを押すとすぐコンパイルするかと聞かれるが、ここでは[いいえ]

パッケージプロジェクトのウィンドウから、オプションボタンを押して、
ディレクトリ/条件タブのユニット出力ディレクトリ欄をobjなどとし、
同じようにobjフォルダを作成する
(Delphi3ではこれは無いのでやらなくても仕方ないです)

それからコンパイルするといいっすよ。


● モジュール一覧

AsyncHttp.pas - 非同期型HTTPコンポーネント
  requires: Sockets.pas

Base64.pas - BASE64エンコーディング関数


CharSetDetector.pas - 日本語文字コード判別を漸進的に行うストリーム的クラス



ChatFilter.pas - 文字列からWindowsの日本語機種依存文字を排除・置き換える関数



ClickableView.pas - 日本語専用のRichEditのような低機能ビューコンポーネント



crc.pas - CRC32算出関数
　zlib内のものをpascal化したものです。


DropURLListTarget - URLリストをDrag Dropで受け取るコンポーネント
  requires: Drag and Drop Component Stuite 3.7 http://www.melander.dk/
　あらかじめ上記コンポーネントをインストールしてある状態でのみ
インストールできます。

TrayIcon.pas - タスクトレイアイコンコンポーネント



UrlFunc.pas - URL関連文字列処理関数
function DecodeRFC822Date( rfc822dateString: string ): TDateTime;
procedure SplitHostPort(s: string; var host:string; var port:integer );
procedure SplitUrl(url: string; var sProtocol, sID, sPassword, sHost, sPort, sPath: string );
function ComplementURL(const relative_uri, base_uri: string): string;


Sockets.pas - ソケットベース処理コンポーネント
　非同期型ソケットコンポーネント及び以下の関数・手続き


SocketIrc.pas - IRC用コンポーネント(未完成)
  requires: Sockets.pas


SmfPlayer.pas - SMFDRV.DLL (C)ajax を使って midi再生をするコンポーネント



Kanjis.pas - 日本語の漢字コードJIS/SJIS変換ユニット
　1文字単位のJIS/SJIS相互変換関数
　文字列全体のJIS/SJIS相互変換関数
　文字列中の半角カナを全角カナに置き換える関数


httpAuth.pas - AsyncHTTPとともに使い、HTTP認証を実現するためのサポートクラス
  requires: AsyncHttp.pas
  requires: MD5.pas  http://www.fichtner.net/delphi/md5.delphi.phtml
　MD5.pasをこのディレクトリなどに配置してからコンパイルしてください。
