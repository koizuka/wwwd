WWWDソースについて
(2004-10-05 戀塚 koizuka@ss.iij4u.or.jp )

このソースはDelphi6update2+rtl3用に記述してあります。

●準備1

以下のものが必要です。

・Drag and Drop Component Suite   (Version 4.1ft4)
http://www.melander.dk/
上記サイトは閉鎖されているのでもうありません・・ので以下にコピーを置いてあります:
 http://www.koizuka.jp/wwwd/source/DragDrop0401ft4.exe
なお、インストールするときに、古すぎるので最新を確認しろ、というような警告が英語で出ますが
実際古いし、その後更新が止まっているものなので気にしないでください(^^;

・拙作componentsモジュール

・Borland提供のTMenuBar
http://www.borland.com/devsupport/delphi/download_files/menubar.zip

・MD5.pas
http://www.fichtner.net/delphi/md5.delphi.phtml


●準備2

Drag and Drop component Suite 4.1ft4をまず先にインストールし、

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
