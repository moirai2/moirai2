userdefinedid="DRA001287"
runinfo="runinfo.txt"
summary="summary.txt"
studyid=`esearch -db sra -query $userdefinedid | efetch -db sra | xtract -pattern EXPERIMENT -element STUDY_REF@accession | sort -u`
echo $studyid
esearch -db sra -query $studyid | efetch -format runinfo > $runinfo
esearch -db sra -query $studyid | efetch -format native -start 1 -stop 2 > $summary

