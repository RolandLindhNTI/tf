require "slim"
require "sinatra"
require "sqlite3"
require "sinatra/reloader"
require 'bcrypt'
require 'sinatra/flash' 
require_relative 'model.rb'

enable :sessions

include Model

before do
    if session[:timeout_arr] == nil
        session[:timeout_arr] = []
    end
    db = database()
    before_all()
end

get('/') do
    slim(:start)
end

get('/cooldown') do
    slim(:"/cooldown", layout: :layout)
end

get('/logout') do
    session[:id] = nil
    session.clear
    flash[:notice] = "You have been logged out!"
    redirect('/')
end

get('/admin') do
    slim(:"/admin/adminpage")
end

get('/register') do
    slim(:"/user/register")
end

get('/login') do
    if session[:cooldown] == true
        redirect('/cooldown')
    end
    slim(:"/user/login")
end

post('/login') do 
    username = params[:username]
    password = params[:password]
    db = database()
    post_login(db,username,password)
end

get('/myannonser') do
    id = session[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE user_id = ? ",id)
    slim(:"advertisement/personal_index",locals:{advertisement:result})
end

post("/users/new") do
    db = database()
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    first_name = params[:first_name]
    last_name = params[:last_name]
    email = params[:email]
    post_register(db, username, password,password_confirm,first_name,last_name,email)
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
            WHERE category_id = ? OR category_id2 = ?",genre,genre)
    else
        result_filter = result
    end
    slim(:"advertisement/index",locals:{advertisement:result,category:result_genre,advert_filter:result_filter})
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
    post_advertupdate(title,description,price,id,user_id,genre,genre2,db)
end

get('/admin/create_genre') do
    slim(:"/admin/create_genre")
end

post('/admin/create_genre') do
    name = params[:name]
    db = database()
    db.execute("INSERT INTO category (name) VALUES(?)",name)
    redirect(:"/admin")
end

get('/admin/advertisements') do
    id = session[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement")
    slim(:"admin/admin_index",locals:{advertisement:result})
end

get('/admin/advertisement/:id/edit') do
    id = params[:id].to_i
    db = database()
    result_genre = db.execute("SELECT * FROM category")
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    slim(:"/advertisement/edit",locals:{result:result,category:result_genre})
end

post('/admin/advertisement/:id/delete') do
    id = params[:id].to_i
    db = database()
    db.execute("DELETE FROM advertisement WHERE id = ?",id)
    db.execute("DELETE FROM ad_category_relation WHERE ad_id = ?",id)
    redirect('/annonser')
end

post('/advertisement/:id/delete') do
    db = database()
    user_id = session[:id].to_i
    id = params[:id].to_i
    user_advert_id = db.execute("SELECT user_id FROM advertisement WHERE id = ?", id).first
    if user_advert_id.nil? || user_id != user_advert_id[0]
        redirect('/')
    end
    db.execute("DELETE FROM advertisement WHERE id = ?",id)
    db.execute("DELETE FROM ad_category_relation WHERE ad_id = ?",id)
    redirect('/')
end

get('/advertisement/:id/edit') do
    db = database()
    user_id = session[:id].to_i
    id = params[:id].to_i
    user_advert_id = db.execute("SELECT user_id FROM advertisement WHERE id = ?", id).first
    if user_advert_id.nil? || user_id != user_advert_id[0]
        redirect('/')
    end
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
    post_advertcheck(title,description,price,id,user_id,genre,genre2,db)
end






#db.last_insert_rowid()
#db.last_insert_row_id()