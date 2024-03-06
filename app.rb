require "slim"
require "sinatra"
require "sqlite3"
require "sinatra/reloader"
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
    slim(:start)
end

get('/logout') do
    session[:id] = nil
    redirect('/')
end

get('/register') do
    slim(:"/user/register")
end

get('/login') do
    slim(:"/user/login")
end

post('/login') do 
    username = params[:username]
    password = params[:password]
    db = database()
    result = db.execute("SELECT * FROM user WHERE username = ?",username).first
    password_digest = result["pwdgst"]
    id = result["id"]

    if BCrypt::Password.new(password_digest) == password
        session[:id] = id
        redirect('/')
    else
        "Fel lösenord"
    end
end

get('/myannonser') do
    id = session[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE user_id = ? ",id)
    p "Alla adverts #{result}"
    slim(:"advertisement/personal_index",locals:{advertisement:result})
end

post("/users/new") do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    first_name = params[:first_name]
    last_name = params[:last_name]
    email = params[:email]

    if (password == password_confirm)
        password_digest = BCrypt::Password.create(password)
        db = database()
        db.execute("INSERT INTO user (username,pwdgst,first_name,last_name,email) VALUES (?,?,?,?,?)",username,password_digest,first_name,last_name,email)
        redirect('/')
    else
        "Lösenorden inte samma"
    end
end

get('/annonser') do
    db = database()
    result = db.execute("SELECT * FROM advertisement")
    p result
    slim(:"advertisement/index",locals:{advertisement:result})
end

post('/advertisement/:id/delete') do
    id = params[:id].to_i
    db = database()
    db.execute("DELETE FROM advertisement WHERE id = ?",id)
    redirect('/annonser')
end

post('/advertisement/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    description = params[:description]
    price = params[:price]
    user_id = params[:user_id].to_i
    db = database()
    db.execute("UPDATE advertisement SET title=?,description=?,price=?,user_id=? WHERE id = ?",title,description,price,user_id,id)
    redirect('/myannonser')
end

get('/advertisement/:id/edit') do
    id = params[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    slim(:"/advertisement/edit",locals:{result:result})
end

get('/advertisement/:id') do
    id = params[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    result_user = db.execute("SELECT username FROM user WHERE id IN (SELECT user_id FROM advertisement WHERE id = ?)",id).first
    slim(:"advertisement/show",locals:{result:result,result_user:result_user})
end

get('/annonser/new') do
    slim(:"advertisement/new")
end

post('/advertisement/new') do
    title = params[:title]
    description = params[:description]
    price = params[:price]
    user_id = session[:id].to_i
    db = database()
    db.execute("INSERT INTO advertisement (title, description, price, user_id) VALUES(?,?,?,?)",title, description, price, user_id) #hur kopplas användar id?
    redirect(:"/annonser")
end

