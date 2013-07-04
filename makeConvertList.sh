#!/bin/bash

CSVFILE=/tmp/jyurrk.csv

#�ǽ��象���Ǵ��Ԥ�ʤ�

#�ǽ��象�������Ϥ��Ƥ�餦
echo '��������ǡ����ΰ��ָŤ��ǽ��象�������Ϥ��Ƥ���������'
read LASTDATE

#����������ťǡ������ϰϤ����
echo '����������ťǡ����γ����������Ϥ��Ƥ���������'
read STARTDATE
echo '����������ťǡ����ν�λ�������Ϥ��Ƥ���������'
read ENDDATE

echo '���Կ��μ�����Ǥ�������'
#�оݴ��Ԥδ����ֹ�����
PTNUMS=`psql -q -t -A -U orca -d orca <<_EOF
SELECT trim(ptnum) FROM tbl_srykarrk s,tbl_ptnum n WHERE s.ptid=n.ptid and lastymd >= '$LASTDATE' ORDER BY n.ptid
_EOF`
#

#�����ֹ��������ꡢ��Ͱ�ͤοǻ�����Ĵ�٤�
PTNUM_ARRY=($PTNUMS)
PTNUM_COUNT=${#PTNUM_ARRY[@]}
#�оݴ��Կ����
echo "�оݤȤʤ봵�Կ��ϡ�${PTNUM_COUNT}�ͤǤ���"


echo '��������ǡ����μ�����Ǥ�������'
JYURRK_ARRY=()
for TARGET in ${PTNUM_ARRY[*]}
do
    JYURRKS=`psql -q -t -A -U orca -d orca -F, <<_EOF
    SELECT trim(n.ptnum),j.sryymd,j.hkncombinum,j.rennum FROM tbl_jyurrk j,tbl_ptnum n WHERE j.ptid=n.ptid and n.ptnum = '$TARGET' and j.edanum = 1 and j.sryymd >= '$STARTDATE' and j.sryymd <= '$ENDDATE' ORDER BY j.sryymd
_EOF`

JYURRK_ARRY=(${JYURRK_ARRY[@]} $JYURRKS)
done

JYURRK_COUNT=${#JYURRK_ARRY[@]}
#��������ǡ��������
echo "��������ϡ�${JYURRK_COUNT}��Ǥ���"

#CSV�ե��������
#CSV�ե�����ι�¤
# �����ֹ�,����ǯ����(20111203),�ݸ��ȹ礻�ֹ�(0001),Ϣ��

if [ -e $CSVFILE ]; then
    rm $CSVFILE
fi

for (( i = 0; i < ${#JYURRK_ARRY[@]}; ++i))
do
    echo ${JYURRK_ARRY[$i]} >> $CSVFILE
done
exit
