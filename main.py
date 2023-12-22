import datetime
from flask import Flask, render_template, request, redirect, url_for, session
from flask_mysqldb import MySQL
from MySQLdb.cursors import DictCursor


app = Flask(__name__, static_url_path='/static')

# Configure MySQL
app.secret_key = "Forum-Secret-Key"
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = '123456' 
app.config['MYSQL_DB'] = 'forum'


mysql = MySQL(app)

#Dabatos Login
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        cur = mysql.connection.cursor()
        cur.callproc('user_login', (username, password))
        result = cur.fetchone()
        cur.close()
        if result:
            session["id"] = result[0]
            return redirect(url_for('category'))
        else:
            return render_template('login.html', error='Invalid username or password')
    return render_template('login.html')

#Dabatos Register
@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        email = request.form['email']
        cur = mysql.connection.cursor()
        cur.callproc('create_user', (username, email, password))
        mysql.connection.commit()
        cur.close()
        return redirect(url_for('login'))
        
    return render_template('register.html')

#Opleda Category
@app.route("/category", methods=["GET", "POST"])
def category():
    if not session.get("id", 0):
        return redirect(url_for("login"))
    if request.method == 'POST':
        name = request.form['name']
        tags = request.form['tags']
        cur = mysql.connection.cursor()
        cur.callproc('add_category', (name, tags))
        result = cur.fetchone()
        cur.nextset()
        mysql.connection.commit()
        cur.close()
        print(result)
        return redirect(url_for("add_post", id=result))
    return render_template('category.html')

##nabua post
@app.route("/post/<int:id>", methods=["GET", "POST"])
def post_details(id):
    if not session.get("id", 0):
        return redirect(url_for("login"))
    cur = mysql.connection.cursor(DictCursor)
    if request.method == "POST":
        content = request.form["content"]
        cur.callproc('add_reply', (id, session["id"], content))
        mysql.connection.commit()
    cur.callproc('get_post', (id,))
    result = cur.fetchone()
    cur.nextset()
    cur.callproc('get_post_replies', (id,))
    replies = cur.fetchall()
    cur.close()
    return render_template('post_details.html', post=result, replies=replies)


@app.route("/", methods=["GET", "POST"])
def post():
    if not session.get("id", 0):
        return redirect(url_for("login"))
    cur = mysql.connection.cursor(DictCursor)
    cur.execute("SELECT * FROM post_view")
    post_list = cur.fetchall()
    cur.close()
    return render_template('post.html', post_list=post_list)


@app.route("/logout")
def logout():
    session["id"] = None
    return redirect(url_for("login"))


@app.route("/post/add", methods=["GET", "POST"])
def add_post():
    if not session.get("id", 0):
        return redirect(url_for("login"))
    if request.method == 'POST':
        title = request.form['title']
        content = request.form['content']
        category_id = request.args.get('id')
        cur = mysql.connection.cursor()
        cur.callproc('add_post', (session["id"], title, content, category_id))
        result = cur.fetchone()
        cur.nextset()
        mysql.connection.commit()
        cur.close()
        return redirect(url_for("post_details", id=result[0]))
    return render_template('add_post.html')

if __name__ == '__main__':
    app.run(debug=True)