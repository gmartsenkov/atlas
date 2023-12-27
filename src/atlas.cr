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

    def relationships
      {{
         @type.instance_vars
           .select { |ivar| ivar.annotation(::Atlas::Relation) }
           .map {|ivar| [ivar.id.stringify, ivar.annotation(::Atlas::Relation)[:model]]}
       }}.to_h
    end
  end

  macro preload(models, relation)
    {%begin%}
      {{models}}.each do |model|
        if x = {{@type}}.relationships[{{relation}}]
          model.{{relation.id}} = x.new(id: 1)
        end
      end
    {%debug%}
    {%end%}
  end

  def to_h
    {{
      @type.instance_vars
        .reject { |ivar| ann = ivar.annotation(::DB::Field); ann && ann[:ignore] }
        .map { |ivar| [ivar.id.stringify, "@#{ivar}".id] }
    }}.to_h
  end

  macro table(name)
    def self.table
      {{name}}.to_s
    end
  end

  macro has_one(name, model)
    @[DB::Field(ignore: true)]
    @[Atlas::Relation(type: :has_one, model: {{model}})]
    property {{name}} : {{model}} | Nil
  end
end
