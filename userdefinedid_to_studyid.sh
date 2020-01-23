userdefinedid=$1
if [[ $userdefinedid =~ 'GSE' ]];then
studyid=`esearch -db gds -query $userdefinedid | elink -target sra | efetch -db sra | xtract -pattern EXPERIMENT -element STUDY_REF@accession | sort -u`
else
studyid=`esearch -db sra -query $userdefinedid | efetch -db sra | xtract -pattern EXPERIMENT -element STUDY_REF@accession | sort -u`
fi
sleep 2
echo $studyid
