# TODO: Write documentation for `Atlas`

annotation Atlas::Relation
end

module Atlas
  VERSION = "0.1.0"

  macro included
    include DB::Serializable
    include DB::Serializable::NonStrict
    extend Methods
  end

  module Methods
    def insert(user, db)
      {% begin %}
        {% cols = [] of String %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::DB::Field) %}
          {% unless ann && ann[:ignore] %}
            {% cols << ivar.id.stringify %}
          {% end %}
        {% end %}

        c = {{cols}}.join(",")
        values = {{cols}}.map_with_index {|col, i| "$#{i+1}" }.join(",")
        query = "insert into users(#{c}) values(#{values})"
        db.exec(query, {{*cols.map {|x| "user.#{x.id}".id }}})
      {% end %}
    end
  end

  macro has_one(t)
    @[DB::Field(ignore: true)]
    @[Atlas::Relation(type: :has_one)]
    property {{t}}
  end
end
