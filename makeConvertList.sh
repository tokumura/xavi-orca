#!/bin/bash

CSVFILE=/tmp/jyurrk.csv

#最終来院日で患者を絞る

#最終来院日を入力してもらう
echo '取得するデータの一番古い最終来院日を入力してください。'
read LASTDATE

#取得する診療データの範囲を指定
echo '取得する診療データの開始日を入力してください。'
read STARTDATE
echo '取得する診療データの終了日を入力してください。'
read ENDDATE

echo '患者数の取得中です・・・'
#対象患者の患者番号を取得
PTNUMS=`psql -q -t -A -U orca -d orca <<_EOF
SELECT trim(ptnum) FROM tbl_srykarrk s,tbl_ptnum n WHERE s.ptid=n.ptid and lastymd >= '$LASTDATE' ORDER BY n.ptid
_EOF`
#

#患者番号の配列を作り、一人一人の診察日を調べる
PTNUM_ARRY=($PTNUMS)
PTNUM_COUNT=${#PTNUM_ARRY[@]}
#対象患者数報告
echo "対象となる患者数は、${PTNUM_COUNT}人です。"


echo '受信履歴データの取得中です・・・'
JYURRK_ARRY=()
for TARGET in ${PTNUM_ARRY[*]}
do
    JYURRKS=`psql -q -t -A -U orca -d orca -F, <<_EOF
    SELECT trim(n.ptnum),j.sryymd,j.hkncombinum,j.rennum FROM tbl_jyurrk j,tbl_ptnum n WHERE j.ptid=n.ptid and n.ptnum = '$TARGET' and j.edanum = 1 and j.sryymd >= '$STARTDATE' and j.sryymd <= '$ENDDATE' ORDER BY j.sryymd
_EOF`

JYURRK_ARRY=(${JYURRK_ARRY[@]} $JYURRKS)
done

JYURRK_COUNT=${#JYURRK_ARRY[@]}
#受信履歴データ数報告
echo "受信履歴は、${JYURRK_COUNT}件です。"

#CSVファイル出力
#CSVファイルの構造
# 患者番号,診療年月日(20111203),保険組合せ番号(0001),連番

if [ -e $CSVFILE ]; then
    rm $CSVFILE
fi

for (( i = 0; i < ${#JYURRK_ARRY[@]}; ++i))
do
    echo ${JYURRK_ARRY[$i]} >> $CSVFILE
done
exit
