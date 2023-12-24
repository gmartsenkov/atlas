require "./spec_helper"
require "db"
require "pg"

class Account
  include Atlas

  property id : Int32
end

class User
  include Atlas

  property id : Int32 | Nil
  property name : String
  property email : String
  property auth0_id : String

  has_one account : Account | Nil
end

adapter = Atlas::Adapter::Postgres.new

describe Atlas do
  it "works" do
    db = DB.open("postgres://localhost/uplisting_development")
    users = User.from_rs(db.query("SELECT * FROM USERS"))
    puts users.first.inspect
    u = users.first
    u.auth0_id = UUID.random.to_s
    adapter.insert(db, u.to_h)
    puts u.inspect
  end
end
