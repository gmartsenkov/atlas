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
    def columns : Array(String)
      {% begin %}
        {% cols = [] of String %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::DB::Field) %}
          {% unless ann && ann[:ignore] %}
            {% cols << ivar.id.stringify %}
          {% end %}
        {% end %}
        {{ cols }}
      {% end %}
    end

    def preload(objects : Array(self), relationship : Symbol)
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
