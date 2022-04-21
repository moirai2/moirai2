cat $input | sort | uniq -c > $uniq
wc $uniq > $count
