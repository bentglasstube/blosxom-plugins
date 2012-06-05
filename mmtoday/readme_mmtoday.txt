MMTodayプラグイン
概要：
　ishinaoさんが tDiary で使っている、MM/Memo (http://1470.net/mm/) の自分のメモをブログに取り込んで「今日のメモ」として表示する機能 (mm_footer.rb, http://tdiary.ishinao.net/20050201.html#p03) に興味が沸いたので、似たような機能を持った blosxom のプラグインを作ってみました。

使い方：
1. mmtoday（プラグイン本体）を、plugins ディレクトリにコピー
2. mmtodayをエディタで開き、
　・$mm_user 変数の中身を、自分のMM/MemoのユーザーIDに書き換える
　・$OUT_DIR 変数の中身を、MMから取り込んだメモをbloxsomのエントリとして保存するentries配下のディレクトリの名前に書き換える（存在しない場合はプラグインが自動的に作成します）
3. mmtoday.tmpl を、plugins/states ディレクトリにコピー（必要であれば修正して下さい）
4. mmtoday.css の中身を、お使いのCSSファイルに追加したり、@importで取り込んだりする（内容は適当に変更して下さい）

　この状態でblosxomを動かすと、$OUT_DIR で指定したディレクトリに、MM/Memoから取得したメモの内容が書かれたファイルが１日単位で作成されます（ファイル名はyyyy_mm_dd.txt、更新時刻は00:00に設定）。

　なお、メモが新しく追加された場合は今日のファイルを作り直しますが、昨日以前のメモの中身を修正しても、このプラグインはファイルを作り直しません。過去のメモの修正を反映したい場合は、$SAVE_FILE 変数で指定されているファイル (mmtoday.dat) を削除してから bloxsom を再表示して下さい。

※実行には XML::RSS, LWP::UserAgent, HTML::Template の各モジュールが必要です

テンプレートの記法：
mmtoday.tmpl
  <TMPL_VAR name="date">        日付 (yyyy/mm/dd)
  <TMPL_VAR name="description">	個々のメモ

その他：
・このプラグインに対するご意見ご要望は、深沢（fukaz55@fo.main.jp）にお願いします。

修正履歴：
05/04/12: 1470.netの文字コード変換ゲートウェイを使用し、UTF-8に変換したRSSを使用することに。
05/03/24: 文字コード変換部分を修正
05/03/16: 初版作成
