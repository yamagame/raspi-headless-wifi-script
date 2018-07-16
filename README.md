# ラズパイ起動時にWiFiとホスト名を設定するスクリプト

WiFiがある環境でラズパイをヘッドレスに使いたい場合のスクリプトです。

ラズパイ起動時に`/boot/net_init.conf`があれば、ファイルに書かれている設定値をシステムに設定してリブートします。
`/boot/net_init.conf`は設定後、`/boot/_net_init.conf`にリネームされます。

リブート後、WiFiに接続されれば、ホスト名を使ってラズパイのIPアドレスを調べることができます。
同じネットワークに繋がっているコンピュータから、以下のコマンドを実行して調べます。

```
$ ping [設定したホスト名].local
```

SSHやVNCを利用するためには、あらかじめ設定しておく必要があります。

## 使い方

### setup-wifi.shを配置する

例えば、以下の場所に配置します。

```
/home/pi/raspi-headless-wifi-script/setup-wifi.sh
```

### /etc/rc.localを編集する

`/etc/rc.local`の`exit 0`の前に以下の1行を追加する。

```
eval 'sudo /home/pi/raspi-headless-wifi-script/setup-wifi.sh'
```

### /boot/net_init.confを作成する

以下は設定例です。`/boot`はPCやmacでマウントできますので、`/boot/net_init.conf`はPCからファイルを配置できます。

```
hostname: "my-raspberrypi-name"
ssid: "wifi-ssid"
psk: "wifi-password"
key_mgmt: "WPA-PSK"
```

- hostname

  ラズベリーパイのホスト名です。

- ssid

  接続したいWiFiのSSIDです。

- psk

  接続したいWiFiのパスワードです。

- key_mgmt

  WiFiのパスワードの指定をするときはこのままにしておいてください。パスワードを指定しない場合はこの行は削除します。
