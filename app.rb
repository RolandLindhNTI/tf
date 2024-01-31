require "slim"
require "sinatra"
require "sqlite3"
require "sinatra/reloader"
require 'bcrypt'

get('/') do
    slim(:index)
end

get('/showlogin') do

end

get('/register') do

end