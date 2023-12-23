require "./spec_helper"
require "db"
require "pg"

class Account
  include Atlas

  property id : Int32
end

class User
  include Atlas

  property id : Int32
  property name : String

  has_one account : Account | Nil
end

describe Atlas do
  it "works" do
    db = DB.open("postgres://localhost/uplisting_development")
    users = User.from_rs(db.query("SELECT * FROM USERS"))
    puts users.first.inspect
    puts User.insert(users.first, db)
  end
end
