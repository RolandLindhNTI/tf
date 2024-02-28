require "slim"
require "sinatra"
require "sqlite3"
require "sinatra/reloader"
require 'bcrypt'

get('/') do
    slim(:start)
end

get('/annonser') do
    db = SQLite3::Database.new("db/plocket.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM advertisement")
    p result
    slim(:"advertisement/index",locals:{advertisement:result})
end

post('/advertisement/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/plocket.db")
    db.execute("DELETE FROM advertisement WHERE id = ?",id)
    redirect('/annonser')

end

get('/advertisement/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/plocket.db")
    db.results_as_hash = true
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
    user_id = params[:user_id].to_i
    db = SQLite3::Database.new("db/plocket.db")
    db.execute("INSERT INTO advertisement (title, description, price, user_id) VALUES(?,?,?,?)",title, description, price, user_id) #hur kopplas användar id?
    redirect(:"/annonser")
end