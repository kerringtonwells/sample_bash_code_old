#!/bin/sh

#Enter Date (A whole month or a specific day in a month) and RTC IP

function enter_search_info {
	echo "Enter date"
	read enter_date
	echo "Enter RTC IP"
	read enter_rtc_ip
}

#Gather Upload Sessions and Completed Sessions

function start_end_session_GS {
	grep "$enter_date" /var/log/mhgs.*|grep Upload|grep Session > START.SESSIONS
	grep "$enter_date"  /var/log/mhgs.*|grep Upload|grep complete > COMPLETE.SESSIONS
	awk '{ print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 }' COMPLETE.SESSIONS > COMPLETE.SESSIONS.tmp
	mv  COMPLETE.SESSIONS.tmp COMPLETE.SESSIONS
	awk '{ print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 " " $10 " " $11 " " $12 " " $13}' START.SESSIONS > START.SESSIONS.tmp
	mv  START.SESSIONS.tmp START.SESSIONS
	awk '{ print $11 " " $13 }' START.SESSIONS > CONTENT_AND_RTC.out
	sort -k6,6 COMPLETE.SESSIONS > COMPLETE.OUT
	sort -k6,6 START.SESSIONS > SESSIONS.OUT
	cut -d " " -f3 SESSIONS.OUT > start.time
	cut -d " " -f3 COMPLETE.OUT > end.time
	cut -d ":" -f1,2,3 start.time > start.time.out
	cut -d ":" -f1,2,3 end.time  > end.time.out
	wc -l end.time > completionCount.out
}

#Creating/Moving the output file (DURATIONS.txt) to the RTC for additional processing

function create_duration_file {
	paste -d "       " DURATION.out START.SESSIONS > TRACKINGOUTPUT.OUT
	paste -d " " start.time.out end.time.out > hold.tmp
	echo -e '\E[37;44m'"\033[1mStart    Finish   Seconds Taken, Asset and Content Location\033[0m"  > DURATIONS.txt
	cut -d " " -f1,7,12 TRACKINGOUTPUT.OUT > hold2.tmp
	paste -d " " hold.tmp  hold2.tmp >> DURATIONS.txt
	scp bytes_to_bits.sh root@$enter_rtc_ip:/var/log
	scp DURATIONS.txt root@$enter_rtc_ip:/var/log
	scp Throughput.sh root@$enter_rtc_ip:/var/log
	scp CONTENT_AND_RTC.out root@$enter_rtc_ip:/var/log
	for i in $enter_rtc_ip ;do ssh root@$i 'hostname;cd /var/log; sh /var/log/Throughput.sh; pwd' ; done
	echo -e '\E[37;44m'"\033[1mssh to $enter_rtc_ip\033[0m"
}

#Creating script that will compare Session start and finish times while converting the diffrence between the two times into Seconds

echo "#!/bin/bash" > obtaindiff.sh
echo "function get_seconds {" >> obtaindiff.sh
echo "   wc -l end.time > completionCount.out " >> obtaindiff.sh
echo "   i="1" " >> obtaindiff.sh
echo "   time2=\`cut -d \" \" -f1 completionCount.out\` " >> obtaindiff.sh
echo "   time=\$[\$time2+1] " >> obtaindiff.sh
echo "   while [ \$i -lt \$time ] " >> obtaindiff.sh
echo "   do " >> obtaindiff.sh
echo "   echo \$i " >> obtaindiff.sh
echo "   head -\$i end.time.out |tail -1 " >> obtaindiff.sh
echo "   head -\$i start.time.out|tail -1 " >> obtaindiff.sh
echo "   date1=\`head -\$i end.time.out |tail -1\` " >> obtaindiff.sh
echo "   date2=\`head -\$i start.time.out|tail -1\` " >> obtaindiff.sh
echo "   date -d @\$(( \$(date -d "\$date1" +%s) - \$(date -d "\$date2" +%s) )) -u +'%H:%M:%S' |xargs echo | awk -F: '{ print (\$1 * 3600) + (\$2 * 60) + \$3 }' >> DURATION.out " >> obtaindiff.sh
echo "   i=\$[\$i+1] " >> obtaindiff.sh
echo "   done " >> obtaindiff.sh
echo "}" >> obtaindiff.sh
echo "" >> obtaindiff.sh
echo "get_seconds" >> obtaindiff.sh

#Creating script that generates the final output containing Start,Finish,Sec,Upload Session ID,File Size in Bytes,Ingest Speeds in Bits Per Sec,RTC IP and Content Name

echo "#!/bin/sh" > Throughput.sh
echo ". bytes_to_bits.sh " >> Throughput.sh
echo "function get_throughput {" >> Throughput.sh
echo "   ls -ltr /r?|grep -v /r|grep -v \"total \"|grep -v .fmpg|grep -v .idx  > assetinventory.tmp" >> Throughput.sh
echo "   sed -i -e 's/\!//g' assetinventory.tmp" >> Throughput.sh
echo "   sed -i -e 's/.mpg//g' assetinventory.tmp" >> Throughput.sh
echo "   sed -i -e 's/\/r[0-9]\///g' DURATIONS.txt" >> Throughput.sh
echo "   sed -i -e 's/\!//g' DURATIONS.txt" >> Throughput.sh
echo "   awk '{ print \$5 \" \" \$9 }' assetinventory.tmp > assetinventory.mpg" >> Throughput.sh
echo "   tail -n +2 DURATIONS.txt > DURATIONS.txt1" >> Throughput.sh
echo "   mv DURATIONS.txt1 DURATIONS.txt" >> Throughput.sh
echo "   sort -k5,5 DURATIONS.txt  > DURATIONS.mpg.sort" >> Throughput.sh
echo "   sort -k2,2 assetinventory.mpg > assetinventory.mpg.sort" >> Throughput.sh
echo "   grep -v \"^[[:blank:]]*\$\" assetinventory.mpg.sort > assetinventory.mpg.sort2" >> Throughput.sh
echo "   mv assetinventory.mpg.sort2 assetinventory.mpg.sort" >> Throughput.sh
echo "   join -a1  -1 5 -2 2  -o 1.1 1.2 1.3 1.4 1.5 2.1 DURATIONS.mpg.sort assetinventory.mpg.sort > final.tmp" >> Throughput.sh
echo "   awk -F' ' '\$6!=\"\"' final.tmp > final1.tmp" >> Throughput.sh
echo "   mv  final1.tmp  final.tmp" >> Throughput.sh
echo "   cut -d \" \" -f3 final.tmp > Seconds.out" >> Throughput.sh
echo "   cut -d \" \" -f6 final.tmp > Bytes.out" >> Throughput.sh
echo "   run_calc" >> Throughput.sh
echo "   paste -d \" \"  final.tmp  bits_per_seconds.asset > final.tmp2" >> Throughput.sh
echo "   awk '{ print \$1 \"      \" \$2 \"       \" \$3 \"       \" \$4 \"         \" \$5 \"	      \" \$6 \"          \" \$7  }' final.tmp2 > final.tmp3" >> Throughput.sh
echo "   mv final.tmp3 final.tmp2" >> Throughput.sh
echo "   echo -e '\E[37;41m'\"\\033[1mStart: Finish:     Sec:    Upload Session ID:      File Size in Bytes:    Ingest Speeds in Bits Per Sec:    RTC IP:     Content Name\\033[0m\" > Asset_bandwidth.txt" >> Throughput.sh
echo "   sed -i -e 's/\/r[0-9]\///g' CONTENT_AND_RTC.out" >> Throughput.sh
echo "   sed -i -e 's/\!//g' CONTENT_AND_RTC.out" >> Throughput.sh
echo "   sort -k1,1 CONTENT_AND_RTC.out > CONTENT_AND_RTC.out.sort" >> Throughput.sh
echo "   mv CONTENT_AND_RTC.out.sort CONTENT_AND_RTC.out" >> Throughput.sh
echo "   join -a1  -1 5 -2 1  -o 1.1 1.2 1.3 1.4 1.6 1.7 2.2 1.5  final.tmp2 CONTENT_AND_RTC.out > final.tmp1" >> Throughput.sh
echo "   mv  final.tmp1 final.tmp2" >> Throughput.sh
echo "   cat final.tmp2 >> Asset_bandwidth.txt" >> Throughput.sh
echo "   awk '{ total += \$6; count++ } END { print total/count }' Asset_bandwidth.txt > average.txt" >> Throughput.sh
echo "   echo -e '\E[37;44m'\"\\033[1mAsset_bandwidth.txt and average.txt files have been generated.\\033[0m\" " >> Throughput.sh
echo "   rm assetinventory.mpg.sort bytes_to_bits.sh bits_per_seconds.asset Bits.out  Bytes.out  Bytes.out.count  assetinventory.tmp  assetinventory.mpg  DURATIONS.mpg.sort  final.tmp2  final.tmp  Seconds.out" >> Throughput.sh
echo "}" >> Throughput.sh
echo "get_throughput" >> Throughput.sh

#Creating Script that Converts bytes into bits and divides bits by seconds

echo "#!/bin/bash" > bytes_to_bits.sh
echo "function run_calc {" >> bytes_to_bits.sh
echo "   wc -l Bytes.out > Bytes.out.count " >> bytes_to_bits.sh
echo "   i="1" " >> bytes_to_bits.sh
echo "   time2=\`cut -d \" \" -f1 Bytes.out.count\` " >> bytes_to_bits.sh
echo "   time=\$[\$time2+1] " >> bytes_to_bits.sh
echo "   while [ \$i -lt \$time ] " >> bytes_to_bits.sh
echo "   do" >> bytes_to_bits.sh
echo "   bytesposition=\`head -\$i Bytes.out  |tail -1\`" >> bytes_to_bits.sh
echo "   echo \"\$((bytesposition * 8))\" >> Bits.out" >> bytes_to_bits.sh
echo "   i=\$[\$i+1]" >> bytes_to_bits.sh
echo "   done" >> bytes_to_bits.sh
echo "   i="1"" >> bytes_to_bits.sh
echo "   while [ \$i -lt \$time ]" >> bytes_to_bits.sh
echo "   do" >> bytes_to_bits.sh
echo "   secondsposition=\`head -\$i Seconds.out  |tail -1\`" >> bytes_to_bits.sh
echo "   bitposition=\`head -\$i Bits.out |tail -1\`" >> bytes_to_bits.sh
echo "   echo "\$\(\(bitposition / secondsposition\)\)" >> bits_per_seconds.asset" >> bytes_to_bits.sh
echo "   i=\$[\$i+1]" >> bytes_to_bits.sh
echo "   done" >> bytes_to_bits.sh
echo "}" >> bytes_to_bits.sh

#Execute functions

enter_search_info
start_end_session_GS

chmod 777 bytes_to_bits.sh
chmod 777 obtaindiff.sh
chmod 777 Throughput.sh

./obtaindiff.sh &&

create_duration_file

rm bytes_to_bits.sh  Throughput.sh   DURATION.out  TRACKINGOUTPUT.OUT hold2.tmp  hold.tmp  COMPLETE.OUT  COMPLETE.SESSIONS  completionCount.out  end.time  end.time.out  SESSIONS.OUT  start.time  start.time.out  START.SESSIONS