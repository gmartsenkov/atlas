class Atlas::Query
  @table : String
  @columns : Array(String)

  getter table
  getter columns

  def initialize(table, columns)
    @table = table
    @columns = columns
  end

  def self.from(klass)
    new(columns: klass.columns, table: "users")
  end

  def to_q
    "SELECT #{@columns.join(",")} from #{@table}"
  end
end
