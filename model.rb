
def database()
    db = SQLite3::Database.new("db/plocket.db")
    db.results_as_hash = true
    return db
end