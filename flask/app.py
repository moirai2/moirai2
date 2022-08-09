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
import moirai2Page
from flask import Flask,url_for,flash,request,Response,redirect,render_template,make_response
from markupsafe import escape
from bs4 import BeautifulSoup 
from werkzeug.utils import secure_filename

############################## flask ##############################
# twitch panels created using https://nerdordie.com/resources/customizable-twitch-panels/
app=Flask(__name__,static_folder='static')
app.config['UPLOAD_FOLDER']='static/upload'
app.secret_key=os.urandom(24)

############################## url ##############################
# https://stackoverflow.com/questions/11994325/how-to-divide-flask-app-into-multiple-py-files
app.add_url_rule("/moirai2/",view_func=moirai2Page.homepage)
app.add_url_rule("/moirai2/commands.html",view_func=moirai2Page.commands)
app.add_url_rule("/moirai2/<path:path>",view_func=moirai2Page.command)
app.add_url_rule("/moirai2/run/",methods=['GET','POST'],view_func=moirai2Page.run)
app.add_url_rule("/moirai2/query/",methods=['GET','POST'],view_func=moirai2Page.query)
app.add_url_rule("/moirai2/db/",methods=['GET','POST'],view_func=moirai2Page.db)
app.add_url_rule("/moirai2/submit/",methods=['GET','POST'],view_func=moirai2Page.submit)

############################## MAIN ##############################

if __name__=="__main__":
    app.run(host="0.0.0.0",debug=True,use_reloader=True)
