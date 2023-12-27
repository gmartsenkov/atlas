require "./spec_helper"
require "db"
require "pg"

class Account
  include Atlas

  table :accounts

  getter id : Int32
  getter user_id : Int32
end

class User
  include Atlas

  table :users

  getter id : Int32 | Nil
  getter name : String
  getter email : String
  getter auth0_id : String

  has_one(account, Account)
end


describe Atlas do
  it "works" do
    db = DB.open("postgres://localhost/uplisting_development")
    adapter = Atlas::Adapter::Postgres.new(db)

    users = adapter.all(Atlas::Query.from(User).to_q, User)
    accounts = adapter.all(Atlas::Query.from(Account).to_q, Account)
    # User.preload(users, :account)
    puts User.relationships
    puts users.first.inspect
    puts accounts.first.inspect
    # u = users.first
    # u.auth0_id = UUID.random.to_s
    # adapter.insert(u.to_h)
    # puts u.inspect
  end
end
