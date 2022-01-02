#!/bin/bash




#Defining Variables
MYPATH="/appsec/github/Github_Realtime"

QUERY=$1
FILTER="o=desc&s=indexed&type=Code"

ALLURLS=${QUERY}_${RANDOM}_${RANDOM}_allurls.txt
TEMPCONTENT=${QUERY}_${RANDOM}_${RANDOM}_tempcontent.txt

# Setting Payloads
declare -a payload_array
payload_array[0]="q=$QUERY&$FILTER"
#payload_array[0]="q=$QUERY&type=code&l=html"

#payload_array[1]="q=$QUERY&o=desc&s=committer-date&type=Commits"

#running loop for payloads
for PAYLOAD in "${payload_array[@]}";
do
echo $PAYLOAD


#running script
COUNT=`curl "https://github.com/search/count?$PAYLOAD" -Ls \
-H "Cookie: user_session=9M328YcwZT-JNLrIkgRpIOxOvk7jrwtERf__5RwaMQkjKbCO"\
|egrep -o ">[0-9KMB]+"| tr -d "><" | sed 's/K/000/' |\
sed 's/M/000000/' | sed 's/B/000000000/'`

echo "$COUNT results found"
PER_PAGE=10

if (($COUNT > 20))
                then 
                PAGES=2
        elif  ((COUNT % 10==0))
                then 
                PAGES=$(($COUNT / $PER_PAGE))

        else   
                PAGES=$(($COUNT / $PER_PAGE+1))
        fi

PAGE=0
while (($PAGE<$PAGES)) 
do

((PAGE++))

GREPFILTER="egrep -iv (\.svg|\.jpg|\.png|\.gif|\.pdf|\.docx|/LICENSE)$"
echo "Trying to fetch data for page no. $PAGE"
URLS=$(curl -s "https://github.com/search?p=$PAGE&$PAYLOAD" -H\
 "Cookie: user_session=9M328YcwZT-JNLrIkgRpIOxOvk7jrwtERf__5RwaMQkjKbCO" |\
egrep -oi "https://github[0-9A-Za-z\!/\._%-]+" | egrep "blob|commit"|$GREPFILTER| sed 's/\/blob\//\/raw\//'|sort -u|\
awk '{if ($0 ~ /\/commit\//) sub(/$/,".patch"); print  }'  |\
tee -a $MYPATH/Results/$ALLURLS )

TOFIND='github'
if grep "$TOFIND"  <<< "$URLS"
then 
echo "yes it is there"
echo " "
FAILED=0
else
echo "no, it is not there"
((PAGE--))

((FAILED++))

echo "It has failed $FAILED times, so sleeping"
for i in {10..0}; do echo -ne "$i\033[0K\r"; sleep 1; done; echo 
        if (($FAILED>10))
        then
        echo "exiting as it has failed too many times" 
        exit
        else
        echo ""
        fi
fi


done #ending pages loop
echo "Task Finished for $PAYLOAD payload."
done #ending payload loop
echo " "
echo " "












echo "####### SCANNING HAS BEGUN ####### "




for URL in `cat $MYPATH/Results/$ALLURLS`
do
curl -s $URL -L> $MYPATH/Results/$TEMPCONTENT

DIGEST=`sha256sum $MYPATH/Results/$TEMPCONTENT |cut -d " " -f 1`
rm $MYPATH/Results/$TEMPCONTENT
DEVELOPER=$(echo $URL|cut -d "/"   -f4,3,4,1 )
REPORTFILE=${RANDOM}${RANDOM}_instantreport_`date +"%Y-%m-%d"`.txt


#echo "$DEVELOPER is developer"
if (`grep -Fxq $URL $MYPATH/scannedurls.txt` && `grep -Fxq $DIGEST $MYPATH/digestdb.txt`)   || `grep -iq $URL blacklist.txt`
then
        echo "$URL has been alreay Scanned" 

	continue
else
	python3 SecretFinder.py -i $URL -o cli| tee $MYPATH/Results/$REPORTFILE
	FILEURL=`echo $URL|sed 's/\/raw\//\/blob\//'`
	FINDINGSCOUNT=$(egrep "\s+\->\s+" $MYPATH/Results/$REPORTFILE|wc -l)





	##Developer email


	COMMITURL=`echo $URL| egrep -io  "https://github[0-9A-Za-z\!/\._%-]+/raw/[a-fA-F0-9]+" |sed 's/\/raw\//\/commit\//'| sed 's/$/\.patch/'`
	DEVELOPEREMAIL=`curl -s $COMMITURL -L|sed -n 2p|awk '{print $NF}'|tr -d "><"`
	if ! grep "@" <<< $DEVELOPEREMAIL
	then 
               DEVELOPEREMAIL="NA"
	fi

	##


	#Sending report only if Significant findings
        if (($FINDINGSCOUNT <2222))
	then 
		aws s3 cp $MYPATH/Results/$REPORTFILE s3://appsec-js-scanner/
		REPORTURL=$(aws s3 presign s3://appsec-js-scanner/$REPORTFILE --expires-in 604800)
        	python3 $MYPATH/abusereporter.py $DEVELOPER $FILEURL $FINDINGSCOUNT $REPORTURL $QUERY $DEVELOPEREMAIL
	fi

	echo "$FINDINGSCOUNT are the total findings"
	echo $URL>> $MYPATH/scannedurls.txt
	echo $DIGEST >> $MYPATH/digestdb.txt
	rm $MYPATH/Results/$REPORTFILE
	
	
	

fi
echo " "

done
 
sort -u -o digestdb.txt $MYPATH/digestdb.txt
sort -u -o scannedurls.txt $MYPATH/scannedurls.txt
rm $MYPATH/Results/$ALLURLS

echo " "
echo " ####### JOB FINISHED ########"
