# rss_crawler
==

RSSフィードのリンク先をスクレイピングしてxml保存する自分用Webスクレイパーです。

保存したxmlはDropboxのpublicフォルダに保存すると公開URLが得られるため、feedly等で読み込むことができます。

Yahoo!Pipesと違いスクリプトを自分で組めるため、効率的な処理と複雑な表現が可能です。

高速化・アクセス規制回避のため、リンク先取得は前回との差分のみ行い、次の取得までには一定時間の待ち時間を設けます。

違うフィードへのアクセスは全て並列で行うため、NAT環境によってはポートが足りなくなるかもしれません。

## 使用方法

nokogiriの関係でRuby 1.9.3でしか動作確認できていません。

インストールは下記でできると思います。

  git clone git@bitbucket.org:emo/rss-crawler.git
  cd rss-crawler
  gem install bundler
  bundle install

上記コマンド実行後、下に示す"設定"を行い、 src/rss_crawler.rb を実行してください。

linuxならcrontab、Windowsならタスクスケジューラでwruby実行を登録しておくと便利です。

## 設定

設定は src/conf.yml で行っています。
サンプルを src/conf_sample.yml に保存していますので、書き換えて src/conf.yml に保存してください。

設定可能項目は下記5つです。
* :save_directory
* :log_directory
* :exe_pipes
* :timeout
* :fp_wait

### :save_directory
xml保存先ディレクトリです。
ここに <フィード名>.xml のファイル名で保存されます。

### :log_directory
ログ保存先です。 <yyyymmdd>.log の形式でファイル名が付けられ、同日の分は追記保存されます。

### :exe_pipes
スクレイピング対象のフィードです。
conf_sample.yml には対象にできるフィードが全て記載されていますので、不要なものを削ってください。
詳しくは conf_sample.yml に記載されています。

### :timeout
全フィードをスクレイピングするまでのタイムアウト値(秒)です。
フィードのリンク先にアクセスする時のタイムアウト値ではありません。

### :fp_wait
フィードのリンク先にアクセスしてから、次のフィードにアクセスするまでにとる待ち時間(秒)です。
連続アクセス規制の対策のために用います。

