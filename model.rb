# Declares a new module
#
module Model

require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'


    # Help function to connect database
    #
    # @return [Hash] db, The database being returned
    def database()
        db = SQLite3::Database.new("db/plocket.db")
        db.results_as_hash = true
        return db
    end

    # Help function to calculate the time dividing to arrays
    #
    # @param [Array] timeout_arr containing float values of times
    # @return [Float] contains the decimal between two times
    def average_timeout(timeout_arr)
        return timeout_arr.sum/timeout_arr.size
    end

    # Timeout function that counts the time between logins and redirects to '/login'
    #
    # @param [Array] timeout_arr containing float values of times
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

    # Help function that enables time
    #
    def annonstime()
        session[:annonstime] = Time.now
    end
    

    # Help function that enables time
    #
    def regtime()
        session[:regtime] = Time.now
    end

    # Function runs before every route, checks for bruteforcing and other malicious intents. Checks authorization for the user depending on the route. 
    # Redirects to one of the following routes depending on the conditions met '/cooldown' '/register' '/'
    #
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



    # Allows the user to login and updates session for the user depending on the criterias met. Redirects to '/login' or '/'. Error-handling and bruteforce prevention.
    # 
    # 
    # @param username [String] The username
    # @param db [Hash] The database
    # @param password [String] The password
    #
    # @see Model#timeout
    def post_login(db,username,password)
        session[:timeout_arr] << Time.now
        timeout(session[:timeout_arr]) 
        result = db.execute("SELECT pwdgst FROM user WHERE username = ?",username).first
        if result != nil && BCrypt::Password.new(result["pwdgst"]) == password
            session[:id] = db.execute("SELECT id FROM user WHERE username = ?",username).first["id"]
            session[:username] = username
            if username == "ADMIN"
                session[:tag] = "ADMIN"
            else
                session[:tag] = "USER"
            end
                redirect('/')
            else
                flash[:notice] = "Fel lösenord eller användarnamn"
                redirect('/login')
        end
    end

    # Creates a new user and checks inputs, uses error-handling to prevent misinputs in the database. Redirects to '/'ssss
    #
    # @param [String] char Containing each forbidden character one by one
    # @param [String] password The users password
    # @param [Hash] db The database
    # @param [String] password_confirm The password again
    # @param [String] first_name The users first name
    # @param [String] last_name The users last name
    # @param [String] email The users email
    #
    # @see Model#regtime
    def post_register(db,username,password,password_confirm,first_name,last_name,email)

        if session[:regtime].nil? || Time.now - session[:regtime] > 20 #To lazy to change this to the new and improved timeout function

            compare_username = db.execute("SELECT username FROM user WHERE username LIKE ?",username).first
            compare_email = db.execute("SELECT email FROM user WHERE email LIKE ?",email).first

            if username.length < 3 || username.empty?
                flash[:notice] = "Användarnmanet få  vara längre än 3 och inte tomt"
                redirect('/')
            elsif password.length > 30
                flash[:notice] = "Lösernordet är för långt"
                redirect('/')
            elsif password.empty? || password.length < 7
                flash[:notice] = "Skriv in ett lösernord"
                redirect('/')
            elsif first_name.empty? || first_name.length > 50
                flash[:notice] = "Fyll i ditt namn"
                redirect('/')
            elsif last_name.empty? || last_name.length > 50
                flash[:notice] = "Fyll i ditt efter namn"
                redirect('/')
            elsif compare_email != nil
                flash[:notice] = "Mailen är redan använd"
                redirect('/')
            elsif username.length > 16
                flash[:notice] = "Användarnamnet är för långt, max 16 karaktärer"
                redirect('/')
            elsif email.length > 320
                flash[:notice] = "Din email är för lång, max 320 karaktärer"
                redirect('/')
            elsif !email.include?("@")
                flash[:notice] = "Din mail måste innehålla domain @"
                redirect('/')
            elsif !email.include?(".com")
                flash[:notice] = "Din mail måste innehålla .com"
                redirect('/')
            end

            forbidden_characters = [" ", ",", ":", ";", "?", "!", "]", "[", "&", "=", "}", "{", "%", "¤", "$", "#", "£", "'", "@", "ä", "å", "ö", "|", "<", ">", "+", "´", "*", "/"]
            forbidden_characters.each do |char|
                if username.include?(char)
                    flash[:notice] = "Ditt användarnamn får inte innehålla symboler som ?,!"
                    redirect('/')
                end
            end

            if (password == password_confirm)
                if compare_username == nil
                password_digest = BCrypt::Password.create(password)
                db.execute("INSERT INTO user (username,pwdgst,first_name,last_name,email) VALUES (?,?,?,?,?)",username,password_digest,first_name,last_name,email)
                flash[:notice] = "Ditt konto har skapats"
                end
            else
                flash[:notice] = "Användarnamnet är upptaget eller så är lösenordet fel"
                redirect('/')
            end
            regtime()
            redirect('/')
        else
            flash[:notice] = "Du måste vänta längre innan du skapar ett konto"
            redirect('/')
        end
    end

    # Creates a new advertisement, contains error handling for certain cases and redirects to '/' or '/annonser' depending on criterias.
    #
    # @param [String] title The title of the advertisement
    # @param [String] description The description of the advertisement
    # @param [String] price The price of the advertisement
    # @param [Integer] user_id The users id
    # @param [Integer] genre Value of the genre selected
    # @param [Integer] genre2 The value of genre2 selected
    # @param [Hash] db The database 
    #
    # @see Model#annonstime
    def post_advertcheck(title,description,price,user_id,genre,genre2,db)

        if session[:annonstime].nil? || Time.now - session[:annonstime] > 5 #Lazy to update this one as well

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

    # Creates a new advertisement, contains error handling for certain cases and redirects to '/' or '/myannonser'
    #
    # @param [String] title The title of the advertisement
    # @param [String] description The description of the advertisement
    # @param [String] price The price of the advertisement
    # @param [Integer] user_id The users id
    # @param [Integer] id The advertisement id
    # @param [Integer] genre Value of the genre selected
    # @param [Integer] genre2 The value of genre2 selected
    # @param [Hash] db The database 
    #
    # @see Model#annonstime
    def post_advertupdate(title,description,price,id,user_id,genre,genre2,db)

        if session[:annonstime].nil? || Time.now - session[:annonstime] > 5 #Lazy to update

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

    # Redirects the user to '/cooldown' if the required criteria is met
    #
    def login_cooldown()
        if session[:cooldown] == true
            redirect('/cooldown')
        end
    end


    # Creates a new category and checks if the category already exists. Redirects to admin page '/admin'
    #
    # @param [String] name The name of the category
    # @param [Hash] db The database
    def post_admincategory(name,db)
        compare_category = db.execute("SELECT name FROM category WHERE name LIKE ?",name).first
        if compare_category == nil
        db.execute("INSERT INTO category (name) VALUES(?)",name)
        else
        flash[:notice] = "Kategorin finns redan"
        redirect(:"/admin")
        end
        redirect(:"/admin")
    end

    # Deletes an already existing advert for the admin. Redirects to advertisements '/annonser'
    #
    # @param [Integer] id The advertisement id
    # @param [Hash] db The database
    def post_admindelete(id,db)
        db.execute("DELETE FROM advertisement WHERE id = ?",id)
        db.execute("DELETE FROM ad_category_relation WHERE ad_id = ?",id)
        redirect('/annonser')
    end

    # Deletes an already existing advert for the user and checks for authorization. Redirects to landing page '/'
    #
    # @param [Hash] db The database
    # @param [Integer] id The advertisement id
    # @param [Integer] user_id The users id
    def post_advertisementdelete(id,user_id,db)
        user_advert_id = db.execute("SELECT user_id FROM advertisement WHERE id = ?", id).first
        if user_advert_id.nil? || user_id != user_advert_id[0]
            redirect('/')
        end
        db.execute("DELETE FROM advertisement WHERE id = ?",id)
        db.execute("DELETE FROM ad_category_relation WHERE ad_id = ?",id)
        redirect('/')
    end


    # Shows a advertisement editing form for an already existing advertisement for the admin. 
    #
    # @param [Hash] db The database
    # @param [Integer] id The advertisement id
    def get_adminadvertisementedit(id,db)
        result_genre = db.execute("SELECT * FROM category")
        result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
        slim(:"/advertisement/edit",locals:{result:result,category:result_genre})
    end

    # Shows a advertisement from the admin page 
    #
    # @param [Hash] db The database
    # @param [Integer] id The advertisement id
    def get_adminadvertisementid(id,db)
        result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
        result_user = db.execute("SELECT username FROM user WHERE id IN (SELECT user_id FROM advertisement WHERE id = ?)",id).first
        slim(:"advertisement/show",locals:{result:result,result_user:result_user})
    end


    # Shows a form for making new advertisements
    #
    # @param [Hash] db The database
    def get_newadvertisement(db)
        result = db.execute("SELECT * FROM category")
        slim(:"advertisement/new",locals:{category:result})
    end

    # Shows the advertisement information for a already existing advertisement
    #
    # @param [Hash] db The database
    # @param [Integer] id The advertisement id
    def get_advertisementid(id,db)
        result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
        result_user = db.execute("SELECT username FROM user WHERE id IN (SELECT user_id FROM advertisement WHERE id = ?)",id).first
        slim(:"advertisement/show",locals:{result:result,result_user:result_user})
    end
    
    # Shows a advertisement editing form for a already existing advertisement. Checks for authorization. Redirects to landing page '/' 
    #
    # @param [Hash] db The database
    # @param [Integer] id The advertisement id
    # @param [Integer] user_id The users id
    def get_advertisementedit(id,db,user_id)
        user_advert_id = db.execute("SELECT user_id FROM advertisement WHERE id = ?", id).first
        if user_advert_id.nil? || user_id != user_advert_id[0]
            redirect('/')
        end
        result_genre = db.execute("SELECT * FROM category")
        result = db.execute("SELECT * FROM advertisement WHERE id = ?",id).first
        slim(:"/advertisement/edit",locals:{result:result,category:result_genre})
    end


    # Shows every advertisement inside the admin panel. 
    #
    # @param [Hash] db The database
    def get_adminadvertisement(db)
        result = db.execute("SELECT * FROM advertisement")
        slim(:"admin/admin_index",locals:{advertisement:result})
    end

    # Shows every advertisement on the website with the option to filter advertisement based on categories.  
    #
    # @param [Hash] db The database
    # @param [Integer] genre The advertisement genre value id
    def get_advertisement(genre,db)
        result = db.execute("SELECT * FROM advertisement")
        result_genre = db.execute("SELECT * FROM category")
        if genre != 0 
            result_filter = db.execute("SELECT * FROM ((ad_category_relation 
                INNER JOIN advertisement ON ad_category_relation.ad_id = advertisement.id) 
                INNER JOIN category ON ad_category_relation.category_id = category.id)  
                WHERE category_id = ? OR category_id2 = ?",genre,genre)
        else
            result_filter = db.execute("SELECT * FROM ad_category_relation INNER JOIN advertisement on ad_category_relation.ad_id = advertisement.id")
        end
        slim(:"advertisement/index",locals:{advertisement:result,category:result_genre,advert_filter:result_filter})
    end
    

    # Shows every advertisement that a specific user has.
    #
    # @param [Hash] db The database
    # @param [Integer] id The users id 
    def personal_advertisement(id,db)
        result = db.execute("SELECT * FROM advertisement WHERE user_id = ? ",id)
        slim(:"advertisement/personal_index",locals:{advertisement:result})
    end

end

