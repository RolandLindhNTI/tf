module Model

require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

    def database()
        db = SQLite3::Database.new("db/plocket.db")
        db.results_as_hash = true
        return db
    end

    def average_timeout(timeout_arr)
        return timeout_arr.sum/timeout_arr.size
    end

    def timeout(timeout_arr)
        timeout_arr = timeout_arr.last(5)
        if timeout_arr.length == 5
        time_intervals = []
        compared_time = timeout_arr[0]
        timeout_arr.each do |time|
            new_time = time - compared_time
            time_intervals << new_time
        end
        if average_timeout(time_intervals) <= 10
            session[:cooldown] = true
            session[:timecheck1] = Time.now
            redirect('/login')
        end
        end
    end


    def annonstime()
        session[:annonstime] = Time.now
    end

    def regtime()
        session[:regtime] = Time.now
    end

    def before_all()
        if session[:cooldown] == true
            session[:timecheck2] = Time.now
            if session[:timecheck2] - session[:timecheck1] > 5
            session[:cooldown] = false 
            session[:timecheck1] = nil
            session[:timecheck2] = nil
            session[:timeout_arr] = nil
            else
            unless request.path_info.include?('/cooldown')
                redirect('/../cooldown')
            end
            end
        end
        protected_routes = ['/myannonser','/advertisement/:id/delete','/advertisement/:id/update','/advertisement/:id/edit','/annonser/new','/admin*']
        login_routes = ['/login','/register']
        if session[:tag] != nil && login_routes.include?(request.path_info)
            redirect('/')
        end
        if session[:id] == nil && protected_routes.include?(request.path_info)
            redirect('/register')
        end
        if session[:tag] != "ADMIN" && request.path_info.include?('/admin')
            redirect('/')
        end
    end

    def post_login(db,username,password)
        session[:timeout_arr] << Time.now
        timeout(session[:timeout_arr]) 
        result = db.execute("SELECT pwdgst FROM user WHERE username = ?",username).first
        if session[:logintime].nil? || Time.now - session[:logintime] > 10
            if result != nil && BCrypt::Password.new(result["pwdgst"]) == password
                session[:id] = db.execute("SELECT id FROM user WHERE username = ?",username).first["id"]
                session[:username] = username
                if username == "ADMIN"
                    session[:tag] = "ADMIN"
                else
                    session[:tag] = "USER"
                end
            else
                flash[:notice] = "Fel lösenord eller användarnamn"
                redirect('/login')
            end
        else
            flash[:notice] = "Du måste vänta längre innan du försöker igen"
            redirect('/login')
        end
    end


    def post_register(db,username,password,password_confirm,first_name,last_name,email)

        if session[:regtime].nil? || Time.now - session[:regtime] > 20

            compare_username = db.execute("SELECT username FROM user WHERE username LIKE ?",username).first

            if username.length > 16
                flash[:notice] = "Användarnamnet är för långt, max 16 karaktärer"
                redirect('/')
            end
            forbidden_characters = [" ", ",", ":", ";", "?", "!", "]", "[", "&", "=", "}", "{", "%", "¤", "$", "#", "£", "'", "@", "ä", "å", "ö", "|", "<", ">", "+", "´", "*", "/"]
            forbidden_characters.each do |char|
                if username.include?(char)
                    flash[:notice] = "Ditt användarnamn får inte innehålla symboler som ?,!"
                    redirect('/')
                end
            end
            
            if email.length > 320
                flash[:notice] = "Din email är för lång, max 320 karaktärer"
                redirect('/')
            end
            if !email.include?("@")
                flash[:notice] = "Din mail måste innehålla domain @"
                redirect('/')
            end

            if (password == password_confirm)
                if compare_username == nil
                password_digest = BCrypt::Password.create(password)
                db.execute("INSERT INTO user (username,pwdgst,first_name,last_name,email) VALUES (?,?,?,?,?)",username,password_digest,first_name,last_name,email)
                end
            else
                flash[:notice] = "Användarnamnet är upptaget eller så är lösenordet fel"
                redirect('/')
            end
            flash[:notice] = "Ditt konto har skapats"
            regtime()
            redirect('/')
        else
            flash[:notice] = "Du måste vänta längre innan du skapar ett konto"
            redirect('/')
        end
    end

    def post_advertcheck(title,description,price,id,user_id,genre,genre2,db)

        if session[:annonstime].nil? || Time.now - session[:annonstime] > 5

            if title.length > 100
                flash[:notice] = "Titeln är för lång"
                redirect('/')
            end
            if description.length > 500
                flash[:notice] = "Beskrivningen är för lång"
                redirect('/')
            end
            if price.length > 50
                flash[:notice] = "Priset är för långt"
                redirect('/')
            end

            if title.nil? || title.strip.empty?
                flash[:notice] = "Titeln på din annons får inte vara tomt."
                redirect('/')
            elsif description.nil? || description.strip.empty?
                flash[:notice] = "Beskrivningen på din annons får inte vara tomt."
                redirect('/')
            elsif price.empty?
                flash[:notice] = "Priset på din annons får inte vara tomt."
                redirect('/')
            end
            db.execute("INSERT INTO advertisement (title, description, price, user_id) VALUES(?,?,?,?)",title, description, price, user_id)
            last_insert_id = db.last_insert_row_id()
            db.execute("INSERT INTO ad_category_relation (ad_id, category_id, category_id2) VALUES(?,?,?)",last_insert_id, genre, genre2)
            annonstime()
            redirect('/annonser')
        else
            flash[:notice] = "Du måste vänta längre innan du kan göra en till annons"
            redirect('/')
        end
    end

    def post_advertupdate(title,description,price,id,user_id,genre,genre2,db)

        if session[:annonstime].nil? || Time.now - session[:annonstime] > 5

            if title.length > 100
                flash[:notice] = "Titeln är för lång"
                redirect('/')
            end
            if description.length > 500
                flash[:notice] = "Beskrivningen är för lång"
                redirect('/')
            end
            if price.length > 50
                flash[:notice] = "Priset är för långt"
                redirect('/')
            end

            if title.nil? || title.strip.empty?
                flash[:notice] = "Titeln på din annons får inte vara tomt."
                redirect('/')
            elsif description.nil? || description.strip.empty?
                flash[:notice] = "Beskrivningen på din annons får inte vara tomt."
                redirect('/')
            elsif price.empty?
                flash[:notice] = "Priset på din annons får inte vara tomt."
                redirect('/')
            end
            db.execute("UPDATE advertisement SET title=?,description=?,price=?,user_id=? WHERE id = ?",title,description,price,user_id,id)
            db.execute("UPDATE ad_category_relation SET category_id=?,category_id2=? WHERE ad_id = ?",genre,genre2,id)
            annonstime()
            redirect('/myannonser')
        else
            flash[:notice] = "Du måste vänta längre innan du kan uppdatera din annons"
            redirect('/')
        end
    end

end

