import os # list files, basename, etc
import re # regular expression
import urllib # access www url and get content
import tempfile # handle temporary file/directory
import shutil # file manipulation mv/cp
import subprocess # execute command line
import sys # sys.stderr, sys.stdout
import datetime # get year/month/date hour/minute/second
import jinja2 # display template HTML with replaced ariables
import xml.etree.ElementTree as ET # Handling XML
import json # handling JSON file format
import gzip # handling gzipped file
import sqlite3 # handling sqlite3 file
from flask import Flask,url_for,flash,request,Response,redirect,render_template,make_response,g
from markupsafe import escape # safe upload
from bs4 import BeautifulSoup # Parsing HTML content
from werkzeug.utils import secure_filename # secure filename

SUBMIT_DIR="../.moirai/ctrl/submit"
COMMAND_DIR="command"

############################## homepage ##############################
def homepage():
    return render_template('index.html')

############################## commands ##############################
def commands():
    commands=[]
    paths=listDir(COMMAND_DIR,-1)
    for path in paths:
        filename=os.path.basename(path)
        hash={"path":path,"filename":filename}
        commands.append(hash)
    return render_template('commands.html',commands=commands)

############################## command ##############################
def command(path):
    print(path,file=sys.stderr)
    command=loadCommand(path)
    return render_template('command.html',command=command)

############################## run ##############################
def run(path):
    content=["Hello World"]
    submitMoirai(content)
    return path

############################## query ##############################
def query():
    return "Hello World"

############################## db ##############################
def db(path):
    cp=subprocess.run(['perl','bin/dag.pl','-d','static/db','-f','json','query',path],stdout=subprocess.PIPE)
    content=cp.stdout
    return path

############################## submit ##############################
def submit(content):
    os.makedirs(SUBMIT_DIR,exist_ok=True)
    writer=open(SUBMIT_DIR+"test.txt",'w')
    writer.writelines(content)
    writer.close()

############################## listDir ##############################
def listDir(path=".",recursion=0,grep=None,ungrep=None):
    array=[]
    files=os.listdir(path)
    for f in files:
        if path==".":file=f
        else:file=path+"/"+f
        if f.startswith("."):continue
        if os.path.isdir(file):
            if recursion==0:continue
            array.extend(listDir(file,recursion-1,grep,ungrep))
            continue
        if grep!=None:
            if not grep.search(f):continue
        if ungrep!=None:
            if ungrep.match(f):continue
        array.append(file)
    return array

############################## loadCommand ##############################
def loadCommand(path):
    reader=open(path,'r')
    j=json.load(reader)
    reader.close()
    input=j["https://moirai2.github.io/schema/daemon/input"]
    output=j["https://moirai2.github.io/schema/daemon/output"]
    bash=j["https://moirai2.github.io/schema/daemon/bash"]
    if not isinstance(input,list): input=[input]
    if not isinstance(output,list): output=[output]
    if not isinstance(bash,list): bash=[bash]
    hash={}
    hash["input"]=input
    hash["output"]=output
    hash["bash"]=bash
    hash["path"]=path
    return hash