#!/usr/bin/env python
import datetime
from inspect import isdatadescriptor
import json
import os
import optparse
import re
import shutil
import subprocess
import sys
import tempfile
import time
############################## updateXML ##############################
def updateXML(dbdir):
    command=["perl","dag.pl","-d",dbdir,"-f","json","query","root->id->$qid"]
    proc=subprocess.run(command,stdout=subprocess.PIPE,text=True)
    hashs=json.loads(proc.stdout)
    totalXml=0
    qids=[]
    for hash in hashs:qids.append(hash["qid"])
    for qid in qids:
        command=["perl","dag.pl","-d",dbdir,"-f","json","query",f"$xml->{qid}/xml/$year#date->$day"]
        proc=subprocess.run(command,stdout=subprocess.PIPE,text=True)
        libraries=json.loads(proc.stdout)
        xmlPerMonth={}
        xmlPerYear={}
        for library in libraries:
            day=library["day"]#2022/01/01
            month=day[0:7]#2022/01
            year=day[0:4]#2022
            if year not in xmlPerYear:xmlPerYear[year]=0
            if month not in xmlPerMonth:xmlPerMonth[month]=0
            xmlPerMonth[month]+=1
            xmlPerYear[year]+=1
            totalXml+=1
            filepath=library["xml"]
            print(f"UPDATE\t{day}->{qid}/day#xml->1")
        for month in xmlPerMonth:
            count=xmlPerMonth[month]
            print(f"UPDATE\t{month}->{qid}/month#xml->{count}")
        for year in xmlPerYear:
            count=xmlPerYear[year]
            print(f"UPDATE\t{year}->{qid}/year#xml->{count}")
        print(f"UPDATE\t{qid}->total#xml->{totalXml}")
############################## updateJson ##############################
def updateJson(dbdir):
    command=["perl","dag.pl","-d",dbdir,"-f","json","query","root->id->$qid"]
    proc=subprocess.run(command,stdout=subprocess.PIPE,text=True)
    hashs=json.loads(proc.stdout)
    totalJson=0
    qids=[]
    os.makedirs("json/latest",exist_ok=True)
    os.makedirs("db/run/latest",exist_ok=True)
    for hash in hashs:qids.append(hash["qid"])
    for qid in qids:
        projectId2json={}
        totalCount={}
        countPerDay={}
        countPerMonth={}
        countPerYear={}
        for key in ["study","sample","experiment","run","json"]:
            totalCount[key]=0
            countPerDay[key]={}
            countPerMonth[key]={}
            countPerYear[key]={}
        #command
        command=["perl","dag.pl","-d",dbdir,"-f","json","query",f"$json->json#date->$date",f"$json->json#sample->$sample",f"$json->json#experiment->$experiment",f"$json->json#run->$run",f"$json->json#filesize->$filesize",f"$json->json#scportalenId->$scportalenId",f"$json->json#projectId->$projectId"]
        proc=subprocess.run(command,stdout=subprocess.PIPE,text=True)
        libraries=json.loads(proc.stdout)
        for library in libraries:
            day=library["date"]#2022/01/01
            month=day[0:7]#2022/01
            year=day[0:4]#2022
            filepath=library["json"]
            jsonCount=1
            studyCount=1
            sampleCount=library["sample"]
            experimentCount=library["experiment"]
            runCount=library["run"]
            scportalenId=library["scportalenId"]
            projectId=library["projectId"]
            if projectId not in projectId2json:projectId2json[projectId]={}
            projectId2json[projectId][day]=filepath
            for key in ["study","sample","experiment","run","json"]:
                if year not in countPerYear[key]:countPerYear[key][year]=0
                if month not in countPerMonth[key]:countPerMonth[key][month]=0
                if day not in countPerDay[key]:countPerDay[key][day]=0
            countPerYear["study"][year]+=studyCount
            countPerYear["sample"][year]+=sampleCount
            countPerYear["experiment"][year]+=experimentCount
            countPerYear["run"][year]+=runCount
            countPerYear["json"][year]+=jsonCount
            countPerMonth["study"][month]+=studyCount
            countPerMonth["sample"][month]+=sampleCount
            countPerMonth["experiment"][month]+=experimentCount
            countPerMonth["run"][month]+=runCount
            countPerMonth["json"][month]+=jsonCount
            countPerDay["study"][day]+=studyCount
            countPerDay["sample"][day]+=sampleCount
            countPerDay["experiment"][day]+=experimentCount
            countPerDay["run"][day]+=runCount
            countPerDay["json"][day]+=jsonCount
            totalCount["study"]+=studyCount
            totalCount["sample"]+=sampleCount
            totalCount["experiment"]+=experimentCount
            totalCount["run"]+=runCount
            totalCount["json"]+=jsonCount
            print(f"UPDATE\t{scportalenId}->scportalenId2projectId->{projectId}")
        for day in countPerDay["study"].keys():
            studyCount=countPerDay["study"][day]
            sampleCount=countPerDay["sample"][day]
            experimentCount=countPerDay["experiment"][day]
            runCount=countPerDay["run"][day]
            jsonCount=countPerDay["json"][day]
            print(f"UPDATE\t{day}->{qid}/day#study->{studyCount}")
            print(f"UPDATE\t{day}->{qid}/day#sample->{sampleCount}")
            print(f"UPDATE\t{day}->{qid}/day#experiment->{experimentCount}")
            print(f"UPDATE\t{day}->{qid}/day#run->{runCount}")
            print(f"UPDATE\t{day}->{qid}/day#json->{jsonCount}")
        for month in countPerMonth["study"].keys():
            studyCount=countPerMonth["study"][month]
            sampleCount=countPerMonth["sample"][month]
            experimentCount=countPerMonth["experiment"][month]
            runCount=countPerMonth["run"][month]
            jsonCount=countPerMonth["json"][month]
            print(f"UPDATE\t{month}->{qid}/month#study->{studyCount}")
            print(f"UPDATE\t{month}->{qid}/month#sample->{sampleCount}")
            print(f"UPDATE\t{month}->{qid}/month#experiment->{experimentCount}")
            print(f"UPDATE\t{month}->{qid}/month#run->{runCount}")
            print(f"UPDATE\t{month}->{qid}/month#json->{jsonCount}")
        for year in countPerYear["study"].keys():
            studyCount=countPerYear["study"][year]
            sampleCount=countPerYear["sample"][year]
            experimentCount=countPerYear["experiment"][year]
            runCount=countPerYear["run"][year]
            jsonCount=countPerYear["json"][year]
            print(f"UPDATE\t{year}->{qid}/year#study->{studyCount}")
            print(f"UPDATE\t{year}->{qid}/year#sample->{sampleCount}")
            print(f"UPDATE\t{year}->{qid}/year#experiment->{experimentCount}")
            print(f"UPDATE\t{year}->{qid}/year#run->{runCount}")
            print(f"UPDATE\t{year}->{qid}/year#json->{jsonCount}")
        totalStudy=totalCount["study"]
        totalSample=totalCount["sample"]
        totalExperiment=totalCount["experiment"]
        totalRun=totalCount["run"]
        totalJson=totalCount["json"]
        print(f"UPDATE\t{qid}->total#study->{totalStudy}")
        print(f"UPDATE\t{qid}->total#sample->{totalSample}")
        print(f"UPDATE\t{qid}->total#experiment->{totalExperiment}")
        print(f"UPDATE\t{qid}->total#run->{totalRun}")
        print(f"UPDATE\t{qid}->total#json->{totalJson}")
        for projectId in projectId2json.keys():
            days=list(projectId2json[projectId].keys())
            days.sort(reverse=True)
            latestDay=days[0]
            filepath=projectId2json[projectId][latestDay]
            #update latest JSON information
            if os.path.isfile(filepath):
                print(f"UPDATE\t{projectId}->projectId2json->{filepath}")
                print(f"UPDATE\t{projectId}->latestDate->{latestDay}")
            #symbolic link latest JSON files
            if os.path.isfile(f"json/{latestDay}/{projectId}.json"):
                source=f"../{latestDay}/{projectId}.json"
                destination=f"json/latest/{projectId}.json"
                if os.path.islink(destination):os.remove(destination)
                os.symlink(source,destination)
            #symbolic link latest run statsitics db files
            if os.path.isfile(f"db/run/{latestDay}/{projectId}.txt"):
                source=f"../{latestDay}/{projectId}.txt"
                destination=f"db/run/latest/{projectId}.txt"
                if os.path.islink(destination):os.remove(destination)
                os.symlink(source,destination)
############################## updateHit ##############################
def updateHit(dbdir):
    command=["perl","dag.pl","-d",dbdir,"-f","json","query","root->id->$qid"]
    proc=subprocess.run(command,stdout=subprocess.PIPE,text=True)
    hashs=json.loads(proc.stdout)
    qids=[]
    for hash in hashs:qids.append(hash["qid"])
    for qid in qids:
        command=["perl","dag.pl","-d",dbdir,"-f","json","query",f"$day->{qid}/hit/$year->$hit"]
        proc=subprocess.run(command,stdout=subprocess.PIPE,text=True)
        libraries=json.loads(proc.stdout)
        countPerMonth={}
        countPerYear={}
        totalHit=0
        for library in libraries:
            day=library["day"]#2022/01/01
            month=day[0:7]#2022/01
            year=day[0:4]#2022
            hit=library["hit"]
            if year not in countPerYear:countPerYear[year]=0
            if month not in countPerMonth:countPerMonth[month]=0
            totalHit+=hit
            countPerYear[year]+=hit
            countPerMonth[month]+=hit
            print(f"UPDATE\t{day}->{qid}/day#hit->{hit}")
        for month in countPerMonth.keys():
            hit=countPerMonth[month]
            print(f"UPDATE\t{month}->{qid}/month#hit->{hit}")
        for year in countPerYear.keys():
            hit=countPerYear[year]
            print(f"UPDATE\t{year}->{qid}/year#hit->{hit}")
        print(f"UPDATE\t{qid}->total#hit->{totalHit}")
############################## MAIN ##############################
parser=optparse.OptionParser()
(options,args)=parser.parse_args()
if len(args)<1:
    print("USAGE: python3 summarizeDb.py dbdir",file=sys.stderr)
    exit(1)
dbdir=args[0]
updateHit(dbdir)
updateXML(dbdir)
updateJson(dbdir)
