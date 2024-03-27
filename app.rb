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
    session.clear
    redirect('/')
end

get('/admin') do
    if session[:tag] == "ADMIN" && session[:username] == "ADMIN"
        slim(:"/admin/adminpage")
    else
        redirect('/')
    end
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

    if result != nil && BCrypt::Password.new(password_digest) == password
        session[:id] = id
        session[:username] = username
        if username == "ADMIN"
            session[:tag] = "ADMIN"
        else
            session[:tag] = "USER"
        end
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
    genre = params[:genre].to_i
    genre2 = params[:genre2].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement")
    result_genre = db.execute("SELECT * FROM category")
    if genre != 0 
        result_filter = db.execute("SELECT * FROM ((ad_category_relation 
            INNER JOIN advertisement ON ad_category_relation.ad_id = advertisement.id) 
            INNER JOIN category ON ad_category_relation.category_id = category.id)  
            WHERE category_id = ? OR category_id2 = ?",genre,genre) #Möjligt att lägga till fler.
    else
        result_filter = result
    end
    #slim(:"advertisement/index",locals:{advertisement:result,category:result_genre})
    slim(:"advertisement/index",locals:{advertisement:result,category:result_genre,advert_filter:result_filter})
end

post('/advertisement/:id/delete') do
    id = params[:id].to_i
    db = database()
    db.execute("DELETE FROM advertisement WHERE id = ?",id)
    db.execute("DELETE FROM ad_category_relation WHERE ad_id = ?",id)
    redirect('/annonser')
end

post('/advertisement/:id/update') do
    id = params[:id].to_i
    genre = params[:genre].to_i
    genre2 = params[:genre2].to_i
    title = params[:title]
    description = params[:description]
    price = params[:price]
    user_id = params[:user_id].to_i
    db = database()
    db.execute("UPDATE advertisement SET title=?,description=?,price=?,user_id=? WHERE id = ?",title,description,price,user_id,id)
    db.execute("UPDATE ad_category_relation SET category_id=?,category_id2=? WHERE ad_id = ?",genre,genre2,id)
    redirect('/myannonser')
end

get('/admin/create_genre') do
    if session[:tag] == "ADMIN" && session[:username] == "ADMIN"
        slim(:"/admin/create_genre")
    else
        redirect('/')
    end
end

post('/admin/create_genre') do
    name = params[:name]
    db = database()
    db.execute("INSERT INTO category (name) VALUES(?)",name)
    redirect(:"/admin")
end

get('/admin/advertisements') do
    if session[:tag] == "ADMIN" && session[:username] == "ADMIN"
    id = session[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement")
    slim(:"admin/admin_index",locals:{advertisement:result})
    else
        redirect('/')
    end
end

post('/advertisement/:id/delete') do
    if session[:tag] == "ADMIN" && session[:username] == "ADMIN"
    id = params[:id].to_i
    db = database()
    db.execute("DELETE FROM advertisement WHERE id = ?",id)
    db.execute("DELETE FROM ad_category_relation WHERE ad_id = ?",id)
    else
        redirect('/')
    end
    redirect('/annonser')
end

get('/admin/advertisement/:id/edit') do
    if session[:tag] == "ADMIN" && session[:username] == "ADMIN"
    id = params[:id].to_i
    db = database()
    result_genre = db.execute("SELECT * FROM category")
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    slim(:"/advertisement/edit",locals:{result:result,category:result_genre})
    else
        redirect('/')
    end
end

get('/advertisement/:id/edit') do
    id = params[:id].to_i
    db = database()
    result_genre = db.execute("SELECT * FROM category")
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    slim(:"/advertisement/edit",locals:{result:result,category:result_genre})
end

get('/advertisement/:id') do
    id = params[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    result_user = db.execute("SELECT username FROM user WHERE id IN (SELECT user_id FROM advertisement WHERE id = ?)",id).first
    slim(:"advertisement/show",locals:{result:result,result_user:result_user})
end

get('/annonser/new') do
    db = database()
    result = db.execute("SELECT * FROM category")
    slim(:"advertisement/new",locals:{category:result})
end

post('/advertisement/new') do
    title = params[:title]
    name = params[:name]
    id = params[:id].to_i
    description = params[:description]
    price = params[:price]
    user_id = session[:id].to_i
    genre = params[:genre].to_i
    genre2 = params[:genre2].to_i
    db = database()
    db.execute("INSERT INTO advertisement (title, description, price, user_id) VALUES(?,?,?,?)",title, description, price, user_id)
    last_insert_id = db.last_insert_row_id()
    db.execute("INSERT INTO ad_category_relation (ad_id, category_id, category_id2) VALUES(?,?,?)",last_insert_id, genre, genre2)
    redirect(:"/annonser")
end






#db.last_insert_rowid()
#db.last_insert_row_id()