require "./spec_helper"
require "db"
require "pg"

class Account
  include Atlas

  property id : Int32
  property user_id : Int32
end

class User
  include Atlas

  property id : Int32 | Nil
  property name : String
  property email : String
  property auth0_id : String

  has_one account : Account | Nil
end


describe Atlas do
  it "works" do
    db = DB.open("postgres://localhost/uplisting_development")
    adapter = Atlas::Adapter::Postgres.new(db)

    users = adapter.all("SELECT * FROM USERS", User)
    accounts = adapter.all("SELECT * FROM ACCOUNTS", Account)
    adapter.all(Atlas::Query.from(User).to_q, User)
    User.preload(users, :account)
    puts users.first.inspect
    puts accounts.first.inspect
    u = users.first
    u.auth0_id = UUID.random.to_s
    # adapter.insert(u.to_h)
    puts u.inspect
  end
end
