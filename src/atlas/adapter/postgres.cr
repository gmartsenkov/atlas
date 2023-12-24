require "db"

class Atlas::Adapter::Postgres < Atlas::Adapter
  def insert(hash)
    hash = hash.reject { |k, v| k == "id" }
    cols = hash.keys.join(",")
    values = hash.keys.map_with_index { |col, i| "$#{i + 1}" }.join(",")
    query = "insert into users(#{cols}) values(#{values}) returning id;"
    inserted_id = db.scalar(query, args: hash.values).as(Int32)
  end

  def all(query, model)
    model.from_rs(@db.query(query))
  end
end
