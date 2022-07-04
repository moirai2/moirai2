import os # list files,basename,etc
import re # regular expression
import urllib # access www url
import tempfile # handle temporary file/directory
import shutil # file manipulation
import subprocess # execute command line
import sys # system
import datetime # handle date and time
import jinja2 # jinja2
import xml.etree.ElementTree as ET
import json
import gzip
from flask import Flask,url_for,flash,request,Response,redirect,render_template,make_response
from markupsafe import escape
from bs4 import BeautifulSoup 
from werkzeug.utils import secure_filename

############################## flask ##############################
# twitch panels created using https://nerdordie.com/resources/customizable-twitch-panels/
app=Flask(__name__,static_folder='static')
app.config['UPLOAD_FOLDER']='static/upload'
app.secret_key=os.urandom(24)
SUBMIT_DIR="../.moirai/ctrl/submit/"
COMMAND_DIR="command/"

############################## homepage ##############################
@app.route("/")
def homepage():
    return render_template('index.html')

############################## commands ##############################
@app.route("/commands.html")
def commands():
    commands=[]
    paths=listDir(COMMAND_DIR,-1)
    for path in paths:
        filename=os.path.basename(path)
        hash={"path":path,"filename":filename}
        commands.append(hash)
    return render_template('commands.html',commands=commands)

############################## command ##############################
@app.route("/command/<path:path>")
def command(path):
    command=loadCommand(path)
    return render_template('command.html',command=command)

############################## run ##############################
@app.route('/run',methods=['GET','POST'])
def run(path):
    content=["Hello World"]
    submitMoirai(content)
    return path

############################## query ##############################
@app.route('/query',methods=['GET','POST'])
def query():
    return "Hello World"

############################## db ##############################
@app.route('/db',methods=['GET','POST'])
def db(path):
    cp=subprocess.run(['perl','bin/rdf.pl','-d','static/db','-f','json','query',path],stdout=subprocess.PIPE)
    content=cp.stdout
    return path

############################## submit ##############################
@app.route('/submit',methods=['GET','POST'])
def submitMoirai(content):
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
    reader=open(COMMAND_DIR+path,'r')
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

############################## MAIN ##############################

if __name__=="__main__":
    app.run(host="0.0.0.0",debug=True,use_reloader=True)
