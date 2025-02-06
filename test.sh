#!/bin/bash
arc=$(uname -a)

#システム情報を全て表示
pcpu=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
#cpuinfoから物理IDを取得し、数字の昇順にソート、重複行を削除し行数をカウント
vcpu=$(grep "^processor" /proc/cpuinfo | wc -l)
#cpuinfoから仮想プロセッサを取得し行数をカウント

fram=$(free -m | awk '$1 == "Mem:" {print $2}')
#ディスクの領域情報をMB単位で出力し、第1フィールド=MEMの行の2フィールド目から抜き出す
uram=$(free -m | awk '$1 == "Mem:" {print $3}')
#ディスクの領域情報をMB単位で出力し、第1フィールド=MEMの行の3フィールド目から抜き出す
pram=$(free | awk '$1 == "Mem:" {printf("%.2f"), $3/$2*100}')
#ディスクの領域情報をKB単位で出力し、MEM業の2フィールド目と3フィールド目を使って使用率(%)を計算

fdisk=$(df -BG | grep '^/dev/' | grep -v '/boot$' | awk '{ft += $2} END {print ft}')
#メモリ情報をGB単位で出力し、devファイル抽出、bootパーテーション除外。抽出したファイルの第2フィールドを足算
udisk=$(df -BM | grep '^/dev/' | grep -v '/boot$' | awk '{ut += $3} END {print ut}')
#メモリ情報をGB単位で出力し、devファイル抽出、bootパーテーション除外。抽出したファイルの第3フィールドを足算
pdisk=$(df -BM | grep '^/dev/' | grep -v '/boot$' | awk '{ut += $3} {ft+= $2} END {printf("%d"), ut/ft*100}')
#メモリ情報をMB単位で出力し、実質udisk/pdiskをすることで使用率を算出

cpul=$(vmstat 1 2 | tail -1 | awk '{printf $15}')
#システムの仮想メモリ統計を2回表示し、2回目の更新の15フィールド目のicを抽出
#2回表示するのは最初の1回分は直前のシステムの状態を反映していない可能性があるから
cpu_op=$(expr 100 - $cpul)
#数値計算コマンドでCPU利用率を計算
cpu_fin=$(printf "%.1f" $cpu_op)
#少数第一位まで出力

lb=$(who -b | awk '$1 == "system" {print $3 " " $4}')
#whoで全現行ユーザの情報を表示し第一フィールドが"system"の業の3フィールド目と4フィールド目を表示

lvmu=$(if [ $(lsblk | awk '{print $6}' | grep "lvm" | wc -l) -eq 0 ]; then echo no; else echo yes; fi)
#lsblkコマンドでディスク構造を表示し、TYPEからLVMのみを抽出し、行数をカウントする。これが0ならno、そうでなければ,yes

ctcp=$(ss -Ht state established | wc -l)
#ヘッダー非表示でTCPソケットデータを付加。確立済みのTCP接続だけ表示し、行数カウントでカウント

ulog=$(users | wc -w)
#ログイン中のユーザー一覧を表示して行数をカウントすることによってユーザー数を算出

ip=$(hostname -I)
#全てのアドレスを表示

mac=$(ip link show | grep "ether" | awk '{print $2}')
#ip link showでネット関係の情報を出力しネットワークのMACアドレスを抽出

cmds=$(journalctl _COMM=sudo | grep COMMAND | wc -l)
#システムログを参照して_COOMのフィルタリングをかけ、行数カウントで実行回数を抽出

#wallコマンドで全ユーザーにメッセージを送信する
wall "    #Architecture: $arc
    #CPU physical: $pcpu
    #vCPU: $vcpu
    #Memory Usage: $uram/${fram}MB ($pram%)
    #Disk Usage: $udisk/${fdisk}Gb ($pdisk%)
    #CPU load: $cpul
    #Last boot: $lb
    #LVM use: $lvmu
    #Connections TCP: $ctcp ESTABLISHED
    #User log: $ulog
    #Network: IP $ip ($mac)
    #Sudo: $cmds cmd"