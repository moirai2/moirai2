from flask import Flask
from flask import render_template
from redis import Redis

app=Flask(__name__,static_folder='static')
redis=Redis(host='redis',port=6379)

@app.route('/')
def homepage():
    return render_template('index.html')

@app.route('/example1.html')
def example1():
    values={"hits":format(redis.incr('hits'))}
    return render_template('example1.html',values=values)
 
@app.route('/example2.html')
def example2():
    values={"val1": 100,"val2" :200}
    return render_template('example2.html',values=values)
 
if __name__=="__main__":
    app.run(host="0.0.0.0",debug=True)