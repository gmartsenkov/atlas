# TODO: Write documentation for `Atlas`

annotation Atlas::Relation
end

module Atlas::Query
  def self.insert(db, hash)
    hash = hash.reject { |k, v| k == "id" }
    cols = hash.keys.join(",")
    values = hash.keys.map_with_index { |col, i| "$#{i + 1}" }.join(",")
    query = "insert into users(#{cols}) values(#{values}) returning id;"
    inserted_id = db.scalar(query, args: hash.values).as(Int32)
  end
end

module Atlas
  VERSION = "0.1.0"

  macro included
    include DB::Serializable
    include DB::Serializable::NonStrict
    extend Methods
  end

  module Methods
    def columns
      {% begin %}
        {% cols = [] of String %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::DB::Field) %}
          {% unless ann && ann[:ignore] %}
            {% cols << ivar.id.stringify %}
          {% end %}
        {% end %}
      {% end %}
    end
  end

  def to_h
    {{
      @type.instance_vars
        .reject { |ivar| ann = ivar.annotation(::DB::Field); ann && ann[:ignore] }
        .map { |ivar| [ivar.id.stringify, "@#{ivar}".id] }
    }}.to_h
  end

  macro has_one(t)
    @[DB::Field(ignore: true)]
    @[Atlas::Relation(type: :has_one)]
    property {{t}}
  end
end
