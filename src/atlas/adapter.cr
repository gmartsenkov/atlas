abstract class Atlas::Adapter
  @db : DB::Database

  def initialize(db)
    @db = db
  end

  abstract def insert(hash)
  abstract def all(query, model)
end
