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

error 404 do
    flash[:notice] = "Routen existerar inte"
    redirect('/')
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
get('/login') do
    login_cooldown()
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
#
# @see Model#personal_advertisement
get('/myannonser') do
    id = session[:id].to_i
    db = database()
    personal_advertisement(id,db)
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
#
# @see Model#get_advertisement
get('/annonser') do
    genre = params[:genre].to_i
    db = database()
    get_advertisement(genre,db)
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
#
# @see Model#post_admincategory
post('/admin/create_genre') do
    name = params[:name]
    db = database()
    post_admincategory(name,db)
end

# Displays every advertisement for the admin on the website
# 
# @see Model#get_adminadvertisement
get('/admin/advertisements') do
    db = database()
    get_adminadvertisement(db)
end


# Displays an advertisement for admin to view
#
# @param [Integer] id The id of the advertisement
#
# @see Model#get_adminadvertisementid
get('/admin/advertisement/:id') do
    id = params[:id].to_i
    db = database()
    get_adminadvertisementid(id,db)
end


# Displays an admin only form to edit an advertisement
#
# @param [Integer] id The id of the advertisement
#
# @see Model#get_adminadvertisementedit
get('/admin/advertisement/:id/edit') do
    id = params[:id].to_i
    db = database()
    get_adminadvertisementedit(id,db)
end

# Removes an advertisement and redirects to the route '/annonser'
#
# @param [Integer] id The id of the advertisement
#
# @see Model#post_admindelete
post('/admin/advertisement/:id/delete') do
    id = params[:id].to_i
    db = database()
    post_admindelete(id,db)
end

# Removes an advertisement and redirects to the landing page route '/'.
#
# @param [Integer] id  The id of the advertisement
#
# @see Model#post_advertisementdelete
post('/advertisement/:id/delete') do
    db = database()
    user_id = session[:id].to_i
    id = params[:id].to_i
    post_advertisementdelete(id,user_id,db)
end

# Displays a form to edit an advertisement
#
# @param [Integer] id The advertisement id
#
# @see Model#get_advertisementedit
get('/advertisement/:id/edit') do
    db = database()
    user_id = session[:id].to_i
    id = params[:id].to_i
    get_advertisementedit(id,db,user_id)
end

# Displays the a single advertisement
# 
# @param [Integer] id The advertisement id
#
# @see Model#get_advertisementid
get('/advertisement/:id') do
    id = params[:id].to_i
    db = database()
    get_advertisementid(id,db)
end

# Displays a form to create a new advertisement
#
# @see Model#get_newadvertisement
get('/annonser/new') do
    db = database()
    get_newadvertisement(db)
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
