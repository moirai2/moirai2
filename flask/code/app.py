from flask import Flask
from pages import views

# twitch panels created using https://nerdordie.com/resources/customizable-twitch-panels/
app=Flask(__name__,static_folder='static')
app.add_url_rule('/',view_func=views.homepage)
app.add_url_rule('/commands.html',view_func=views.commands)
app.add_url_rule('/command/<path:path>',view_func=views.command)
app.add_url_rule('/run/<path:path>',methods=['GET','POST'],view_func=views.run)

if __name__=="__main__":
    app.run(host="0.0.0.0",debug=True,use_reloader=True)
