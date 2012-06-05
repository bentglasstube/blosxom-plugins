newentry プラグインについて

■概要
　newentry プラグインは、いわゆる「掲示板」のイメージで新しいエントリを追加できるプラグインです。blosxom をベースに掲示板を運用したい時に使用できます。
　また、エントリに対してコメントがあった場合は、普通のブログのようにエントリを時系列に表示するのではなく、スレッドフロート型掲示板のように、最新のコメントがあった順番にエントリを並べ替える機能もあります。

　前に作ったバージョンはあまりに多機能すぎて設定するのもメンテするのも面倒だったので、不要と思われる機能をバッサリ削って上記の機能のみに絞りました。
　多分、これだけあれば機能としては十分だと思います。


■注意事項
　このプラグインの動作には、別途 writeback プラグインが必要です。
　（ないとエントリに対するコメントの書き込みができないので、掲示板になりません）

　また、このプラグインは、kyo さん制作の blosxom Starter Kit (以下"BSK") を使用して blosxom をインストールしていることを前提とした作りになっています。具体的には、BSK の config.cgi に書かれた、writebackプラグインの変数の値を参照しています。
　もしBSKを使わずにblosxomを運用している時は、別途プラグインの設定が必要になります。

　blosxom Starter Kit: http://hail2u.net/archives/bsk.html


■インストールと前準備
　解凍すると、以下のファイルが出てきます。

plugins
 newentry  プラグイン本体
           プラグインのディレクトリ(plugins)に設定します。

entries
 newentry.html  入力フォームの雛形（フォーム表示時にはこれを読み込みます）
 writeback.html writeback の内容を通常時に表示するために必要なフレーバー（適当に修正して下さい）
                それぞれ、フレーバーのディレクトリ(entries)に設定します。

　現在ご使用になっているフレーバーに、下記の記述を適宜追加して下さい。

$newentry::form         入力フォームを表示（newentry.html の内容を展開します）
$newentry::response     newentry からのメッセージを表示
$newentry::date         エントリの更新日時文字列（story で使用可能）
$writeback::writebacks  story.html の $body の下に埋め込むことにより、エントリに対するコメントが（writeback.htmlが適用された形で）この部分に表示されるようになります。より表示が掲示板っぽく。

　そして、Blosxomのデータディレクトリ(entries)に、書き込みファイルを保存する用のディレクトリ（例：bbs）を作成して下さい。
　ここまでやった状態でblosxomを再表示すれば、入力フォームが出てきて掲示板として使える状態になっているんじゃないかと思います。多分。


■設定項目の説明
　プラグインの細かい設定は、プラグインのソースの中の変数をいじることによって行います。
　普通はそんなにいじらなくて良いと思います。

# このプラグインの名前
$newentry_plugin_name = "newentry";
　フォームから入力された場合、このプラグイン向けの書き込みかどうかを判断するために使用する名称。
　以下の記述を、フォームの中に必ず入れておいて下さい。
　<input type="hidden" name="plugin" value="newentry" />

# エントリを追加するデフォルトのディレクトリ名
$newentry_category = "bbs";
　フォームから入力された書き込みを保存する、$blosxom::data_dir 配下のディレクトリの名前。
　「インストールと前準備」の時に作成したディレクトリの名前を設定して下さい。

# 作成するファイルの拡張子
$file_extension = $blosxom::file_extension;
　フォームから入力された書き込みを保存する際に設定する拡張子。
　通常はこのままで良いです。

# 許可するコメントのバイト数（最大）
$max_length_comment = 8096;
　書き込み時のコメントの最大バイト数。
　特に制限しない場合は、0を設定して下さい。

# 許可するコメントのバイト数（最小）
$min_length_comment = 40;
　書き込み時のコメントの最小バイト数。一言コメントを書かれるのが嫌な場合用。
　特に制限しない場合は、0を設定して下さい。

# 許可する改行の数
$denyret = 30;
　一回の投稿の中に含まれる改行の数の最大値。「荒らし」対策の一つ。
　特に制限しない場合は、0を設定して下さい。

# 同一IPから許可する書き込み間隔（秒）
$deny_timesrc = 60;
　同一のIPアドレスからの連続投稿があった場合、許可する投稿間隔の指定。「荒らし」対策の一つ。
　特に制限しない場合は、0を設定して下さい。

# エントリ１行目のフォーマット
# $title: 入力タイトル / $name: 名前(URLかe-mailへのリンク込み)
# title がない場合、$name が使用されます
$format_first_line = '$title ($name)';
　フォームから投稿された書き込みはファイルとして保存されますが、それの１行目のフォーマット（blosxomではエントリのタイトルとみなされる）を指定します。
　url 欄に URI やメールアドレスが入力されていた場合、$name にはそれへのリンクが自動的に設定されます。

# Writebackがあったエントリを上位に持ってくる機能（いわゆるage）を使用？
$use_age = 1;
　この変数が0以外の場合、エントリの更新時刻は（エントリが投稿された時刻ではなく）このエントリに最後に Writeback された時の時刻とみなすようになります。
　結果的に、最近Writeback があったエントリほど上に表示されます。

# デフォルトのフォーム
my $def_form_template =<<'FORM_';
（中略）
FORM_
　フレーバー用のディレクトリに "newentry.html" というファイルがない場合、ここで書かれたフォームを使用します。

# クッキー
my $cookie_expires = $blosxom::writeback_cookie_expires;
my $cookie_domain = $blosxom::writeback_cookie_domain;
my $cookie_path = $blosxom::writeback_cookie_path;
　それぞれ、サーバのドメイン、blosxom を設置したパス、保存期間を設定しています。
　$blosxom::writeback_～ という変数は BSK の config.cgi で設定されているものです。BSK を使っていない場合は、writeback プラグインの同名の変数の値をそのまま使用して下さい。

# writebackのデータを保存するディレクトリ名
$writeback_dir = $blosxom::writeback_dir;

# writebackのデータファイルの拡張子
$writeback_file_extension = $blosxom::writeback_file_extension;
　どちらも、writeback プラグインで設定してある値と同じものを設定しています。


■ご注意
・表示順番をいじっているので、paginate などのページ制御系のプラグインとは相性が悪いです。
　どうしてもページ制御したい場合は、$use_age を 0 に設定して下さい。

・まだあまりテストしてません。
　ご利用は自己責任で！（流行ワード）

・バグ報告や要望などがありましたら、私まで連絡して下さい。
　この掲示板は、http://cwww.pos.to/bbs/ で動かしています。

・再配布や改変はご自由にどうぞ。
　newentryプラグインとドキュメントの著作権は私（深沢　豪）にあります。


■謝辞
　このプラグインを作るにあたり、以下のモジュールやプラグインを参考にさせて頂きました。

blosxom 2.0 http://www.blosxom.com/
Blosxom Starter Kit http://hail2u.net/archives/bsk.html (hai2u.net / kyo さん)
writeback プラグイン http://www.blosxom.com/plugins/input/writeback.htm


■履歴
2004/04/29 初版作成
2005/05/28 機能限定版作成
2005/08/20 XSS脆弱性対応（andi＠れっつ日記さん、ご指摘ありがとうございました）

