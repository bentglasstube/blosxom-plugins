awsxomプラグイン
概要：
　エントリの中に書かれた ASIN(Amazon の商品コード)、および ISBN を見つけたら Amazon Web Services を使って情報を取得する機能を持った、blosxom用のプラグインです。
　Perl5＋LWP::UserAgentが使えるサーバで動作します。

インストール：
1. awsxom（プラグイン本体）を、plugins ディレクトリにコピー

2. awsxom をエディタで開き、
　・$asoid 変数の中身を、自分のAmazonアソシエイトIDに書き換える
　・$devkey 変数の中身を、自分のAmazon Web Services のデベロッパートークンに書き換える
　・必要があれば、$EXPIRE 変数（AWSにアクセスする間隔。単位：時間）や $cachedir 変数（AWSから取得したXMLをキャッシュするディレクトリ。なければ自動作成します）を変更

3. awsxom.html（および、必要があれば awssimple.html）を、entries ディレクトリにコピー。
　 内容については後述します。

使い方：
　エントリの記事の中に

ASIN:(ASINコード)
ISBN:(ISBNコード)

　と書くと、該当する商品の情報をAmazonから取得し、awsxom.html の記述で拡張されたものに置き換わります。

使い方２：
ASIN:(ASINコード):(テンプレート名):
ISBN:(ISBNコード):(テンプレート名):

　と記述すると、awsxom.html の代わりにテンプレート名で記述されたファイルをテンプレートとして使用します（新機能）。
　awssimple.htmlをテンプレートとして使用する場合、「ASIN:1234567890:awssimple:」という形で記述します。

テンプレートファイルについて：
　entries/awsxom.html（および awssimple.html）は、Amazon から取得した情報を表示する時のテンプレートファイルです（文字コードはUTF-8）。お好きなように拡張して下さい。
　以下の変数が使用可能です：

$Asin		ASIN/ISBNコード
$ProductName	商品名
$Catalog	Amazon内部でのカタログ名(Book,Music,etc..)
$ReleaseDate	発売日
$Manufacturer	発行元
$ImageUrlSmall	商品画像のURL（小）
$ImageUrlMedium	商品画像のURL（中）
$ImageUrlLarge	商品画像のURL（大）
$Availability	在庫状況
$ListPrice	定価
$OurPrice	Amazonでの販売価格
$UsedPrice	マーケットプレイスでの価格
$Author		本の場合は著者名、CDなどの場合はアーティスト名。複数の著者がいる場合、","で連結します
$Artist		アーティスト名
$Link		Amazonへのリンク。こんな形の文字列が入ります
		http://www.amazon.co.jp/exec/obidos/ASIN/(ASINコード)/ref=nosim/アソシエイトID

　エラーが発生した場合、代わりにAmazonが返したエラーメッセージが表示されます。

注意点：
　このプラグインは内部で文字コード変換を行っていないので、UTF-8以外で運用しているblosxomのサイトではこのままでは使えません。必要であれば改造して下さい（なげやり）。

その他：
・このプラグインに対するご意見ご要望は、深沢（fukaz55@fo.main.jp, http://fukaz55.main.jp/）にお願いします。
・このプラグインを使って発生した利益や損失については、私は責任を取りません。

参考：
・mt-bk1 Plugin（河野武さん、http://smashmedia.jp/blog/archives/000091.php）
・MTAws Plugin（Daiji Hirataさん、http://amazon.uva.ne.jp/log/archives/001345.html）
・自分で作るblogツール（石川直人さん、ソフトバンクパブリッシング、ISBN:4797327073）

更新記録：
05/09/03
　テンプレートを指定できるように修正

