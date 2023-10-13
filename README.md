# 構築手順

## 仮想環境の構築

dockerおよびdocker-composeがインストールされているlinuxにログインし、以下のスクリプトでgithubにログインする。
（YOUR_TOKEN、USERNAMEは自分のトークンとIDに置き換える）

```shell
export CR_PAT=YOUR_TOKEN
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

以下のtarファイルを任意のディレクトリにダウンロードし、解凍する。

```shell
wget https://raw.githubusercontent.com/mori-te/sinatra_test/master/study_site.tar.gz
tar fxvz study_site.tar.gz
```

以下を実行してコンテナを作成する。

```shell
cd study_site
docker-compose up -d
```

## ソースコードの展開

study-app2コンテナにアクセスする。

```shell
docker exec -it study-app2 /bin/bash
```

ディレクトリを作成し、ソースコードを取得する。

```shell
cd /root; mkdir webapps; cd webapps
git clone https://github.com/mori-te/sinatra_test.git
```

## データの登録

```shell
yum install mysql -y
cd /root/webapps/sinatra_test/db
sed -e '5,6d' tables.sql > /tmp/tables.sql
mysql study -u study -pstudy -h study-mysql2 < /tmp/tables.sql
mysql study -u study -pstudy -h study-mysql2 < master.sql
mysql study -u study -pstudy -h study-mysql2 < languages.sql
mysql study -u study -pstudy -h study-mysql2 < questions.sql
```

## rubyのライブラリのインストール＆shellセットアップ

```shell
cd /root/webapps/sinatra_test
bundle install
adduser guest
bundle exec rackup -p 4567 -o 0.0.0.0
```

## 画面表示方法

```
http://<ip address>:4567/
```
ID: guest, PW: guest!

