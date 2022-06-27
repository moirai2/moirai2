from flask import request, render_template
import os
import json

SUBMIT_DIR="../.moirai/ctrl/submit/"
COMMAND_DIR="command/"

def homepage():
    return render_template('index.html')

def commands():
    commands=[]
    paths=listDir(COMMAND_DIR,-1)
    for path in paths:
        filename=os.path.basename(path)
        hash={"path":path,"filename":filename}
        commands.append(hash)
    return render_template('commands.html',commands=commands)

def command(path):
    command=loadCommand(path)
    return render_template('command.html',command=command)

def run(path):
    content=["Hello World"]
    submitMoirai(content)
    return path

def submitMoirai(content):
    os.makedirs(SUBMIT_DIR,exist_ok=True)
    writer=open(SUBMIT_DIR+"test.txt",'w')
    writer.writelines(content)
    writer.close()

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
