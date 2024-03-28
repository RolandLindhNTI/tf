require "slim"
require "sinatra"
require "sqlite3"
require "sinatra/reloader"
require 'bcrypt'
require 'sinatra/flash' 
require_relative 'model.rb'

enable :sessions


include Model


# Runs before every route is being ran, checks login cooldowns and authorization
#
# @param :timeout_arr [Array] containing float values of times 
# @see Model#before_all    
before do
    if session[:timeout_arr] == nil
        session[:timeout_arr] = []
    end
    db = database()
    before_all()
end


# Displays landing page
#
# 
get('/') do
    slim(:start)
end

# Displays cooldown page
#

get('/cooldown') do
    slim(:"/cooldown", layout: :layout)
end

# Displays a logout message and clears sessions. Redirects the user to the landing page route '/'
#
# @param :id [Integer]
# @param :notice [String] message
get('/logout') do
    session[:id] = nil
    session.clear
    flash[:notice] = "You have been logged out!"
    redirect('/')
end

# Displays admin control panel.
#
get('/admin') do
    slim(:"/admin/adminpage")
end

# Displays a register form
#

get('/register') do
    slim(:"/user/register")
end

# Displays a login form, redirects the user to the route '/cooldown' if conditions are met
#
# @param [Boolean] :cooldown True or false
get('/login') do
    if session[:cooldown] == true
        redirect('/cooldown')
    end
    slim(:"/user/login")
end

# Attempts to login in user and updates the session
#
# @param [String] :username The username
# @param [String] :password The password
#
# @see Model#post_login
post('/login') do 
    username = params[:username]
    password = params[:password]
    db = database()
    post_login(db,username,password)
end


# Displays all the users advertisements
#
# @param [Integer] id The users id
get('/myannonser') do
    id = session[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE user_id = ? ",id)
    slim(:"advertisement/personal_index",locals:{advertisement:result})
end

# Creates a new user and updates authorization and sessions for the newly created user
#
# @param [String] username The username
# @param [String] password The password
# @param [String] password_confirm The password again
# @param [String] first_name The first name
# @param [String] last_name The last name
# @param [String] email The email
#
# @see Model#post_register
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

# Displays every advertisement on the website, possible to filter advertisements based on genre.
#
# @param [Integer] genre The genre
# @param [Integer] genre2 The other genre
get('/annonser') do
    genre = params[:genre].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement")
    result_genre = db.execute("SELECT * FROM category")
    if genre != 0 
        puts "Genre is not 0. Genre: #{genre}"
        result_filter = db.execute("SELECT * FROM ((ad_category_relation 
            INNER JOIN advertisement ON ad_category_relation.ad_id = advertisement.id) 
            INNER JOIN category ON ad_category_relation.category_id = category.id)  
            WHERE category_id = ? OR category_id2 = ?",genre,genre)

        puts "Result filter: #{result_filter.inspect}"
    else
        puts "Genre is 0. Fetching all advertisements."
        result_filter = db.execute("SELECT * FROM ad_category_relation INNER JOIN advertisement on ad_category_relation.ad_id = advertisement.id")
        puts "Result filter: #{result_filter.inspect}"
    end
    slim(:"advertisement/index",locals:{advertisement:result,category:result_genre,advert_filter:result_filter})
end

# Updates an article
#
# @param [Integer] id The advertisements id
# @param [Integer] genre The genre
# @param [Integer] genre2 The genre2
# @param [String] title The title of the advertisement
# @param [String] description The description of the advertisement
# @param [String] price The price
# @param [Integer] user_id The users id
#
# @see Model#post_advertupdate

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

# Displays a form to create a genre
#
get('/admin/create_genre') do
    slim(:"/admin/create_genre")
end

# Creates a genre, updates the database and redirects to the route '/admin'
# 
# @param [String] name The name of the genre
post('/admin/create_genre') do
    name = params[:name]
    db = database()
    db.execute("INSERT INTO category (name) VALUES(?)",name)
    redirect(:"/admin")
end

# Displays every advertisement on the website
# 
#
get('/admin/advertisements') do
    db = database()
    result = db.execute("SELECT * FROM advertisement")
    slim(:"admin/admin_index",locals:{advertisement:result})
end


# Displays an advertisement for admin to view
#
# @param [Integer] id The id of the advertisement
get('/admin/advertisement/:id') do
    id = params[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    result_user = db.execute("SELECT username FROM user WHERE id IN (SELECT user_id FROM advertisement WHERE id = ?)",id).first
    slim(:"advertisement/show",locals:{result:result,result_user:result_user})
end


# Displays an admin only form to edit an advertisement
#
# @param [Integer] id The id of the advertisement

get('/admin/advertisement/:id/edit') do
    id = params[:id].to_i
    db = database()
    result_genre = db.execute("SELECT * FROM category")
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    slim(:"/advertisement/edit",locals:{result:result,category:result_genre})
end

# Removes an advertisement and redirects to the route '/annonser'
#
# @param [Integer] id The id of the advertisement
post('/admin/advertisement/:id/delete') do
    id = params[:id].to_i
    db = database()
    db.execute("DELETE FROM advertisement WHERE id = ?",id)
    db.execute("DELETE FROM ad_category_relation WHERE ad_id = ?",id)
    redirect('/annonser')
end

# Removes an advertisement and redirects to the landing page route '/'.
#
# @param [Integer] user_id The id of the user
# @param [Integer] id  The id of the advertisement
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

# Displays a form to edit an advertisement
#
# @param [Integer] user_id The users id
# @param [Integer] id The advertisement id
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

# Displays the a single advertisement
# 
# @param [Integer] id The advertisement id
get('/advertisement/:id') do
    id = params[:id].to_i
    db = database()
    result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
    result_user = db.execute("SELECT username FROM user WHERE id IN (SELECT user_id FROM advertisement WHERE id = ?)",id).first
    slim(:"advertisement/show",locals:{result:result,result_user:result_user})
end

# Displays a form to create a new advertisement
#
#
get('/annonser/new') do
    db = database()
    result = db.execute("SELECT * FROM category")
    slim(:"advertisement/new",locals:{category:result})
end


# Creates a new advertisment and redirects to the route '/annonser'
#
# @param [String] title The title of the advertisement
# @param [String] description The description of the advertisement
# @param [String] price The price of the advertisement
# @param [Integer] user_id The users id
# @param [Integer] genre The genre of the advertisement
# @param [Integer] genre2 The other genre of the advertisement
#
# @see Model#post_advertcheck

post('/advertisement/new') do
    title = params[:title]
    description = params[:description]
    price = params[:price]
    user_id = session[:id].to_i
    genre = params[:genre].to_i
    genre2 = params[:genre2].to_i
    db = database()
    post_advertcheck(title,description,price,user_id,genre,genre2,db)
end






#db.last_insert_rowid()
#db.last_insert_row_id()