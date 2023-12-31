require "./spec_helper"
require "db"
require "pg"

class Account < Atlas::Relation
  table :accounts

  getter id : Int32
  getter user_id : Int32

  has_one(account_configuration, AccountConfiguration, {id: :account_id})
end

class AccountConfiguration < Atlas::Relation
  table :account_configurations

  getter id : Int32
  getter account_id : Int32
end

class User < Atlas::Relation
  table :users

  getter id : Int32 | Nil
  getter name : String
  getter email : String
  getter auth0_id : String

  has_one(account, Account, {id: :user_id})
  has_one(notification, Notification, {id: :user_id})
end

class Notification < Atlas::Relation
  table :notification_settings

  getter id : Int32
  getter user_id : Int32
  getter daily_summary : Bool
end

describe Atlas do
  it "works" do
    db = DB.open("postgres://localhost/uplisting_development")
    adapter = Atlas::Adapter::Postgres.new(db)

    users = adapter.all(Atlas::Query.from(User).to_q, User)
    accounts = adapter.all(Atlas::Query.from(Account).to_q, Account)
    puts users[1].inspect
    User.preload_account(db, users)
    puts users[1].inspect
    puts User.relationships
    puts "---USERS---"
    User.relationships.each do |k,v|
      puts v.model.table
      puts v.model.columns
    end
    puts "---ACCOUNTS---"
    Account.relationships.each do |k,v|
      puts v.model.table
      puts v.model.columns
    end
    # puts users.first.inspect
    # puts accounts.first.inspect
    # u = users.first
    # u.auth0_id = UUID.random.to_s
    # adapter.insert(u.to_h)
    # puts u.inspect
  end
end
