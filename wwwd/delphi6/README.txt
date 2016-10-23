WWWDソースについて
(2001-04-28 戀塚 koizuka@ss.iij4u.or.jp )

このソースはDelphi5用に記述してあります。

●準備1

以下のものが必要です。

・Drag and Drop Component Suite   (Version 3.7)
http://www.melander.dk/

・拙作componentsモジュール

・Borland提供のTMenuBar
http://www.borland.com/devsupport/delphi/download_files/menubar.zip

・MD5.pas
http://www.fichtner.net/delphi/md5.delphi.phtml


●準備2

Drag and Drop component Suite 3.7をまず先にインストールし、

componentsを展開し、そこにMD5.pasもコピーし、それらを
まとめてパッケージとして作成、インストールします。

●準備3

WWWDのソースを展開したディレクトリに、obj というディレクトリを作成します。

これらが済んでから、wwwd.dprを開いてください。
エラーなく開ければOKです。

●ソースの解説

wc_main.pas - メインモジュール
CheckItem.pas - アイテム一つの管理クラス
CheckGroup.pas - グループ一つの管理クラス
IgnorePattern.pas - 無視パターン処理
HtmlSize.pas - 本文サイズ・CRC計算
crc.pas - CRC32計算
DecompressionStream2.pas - 漸進的inflate

localtexts.pas - 文字列定数

ItemPropery.pas - アイテムのプロパティダイアログ
GroupProperty.pas - グループのプロパティダイアログ
OptionDlg.pas - オプション設定ダイアログ
About.pas - about dialog
FindDlg.pas - 検索ダイアログ
