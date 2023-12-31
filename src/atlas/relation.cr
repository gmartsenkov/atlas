class Atlas::Relation
  @@columns = Array(String).new

  macro inherited
    include DB::Serializable
    include DB::Serializable::NonStrict
    extend Methods
  end

  def self.table
    nil
  end

  def self.columns
    nil
  end

  class RelationshipInfo
    getter model : Atlas::Relation.class

    def initialize(model)
      @model = model
    end
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

    def relationships : Hash(String, RelationshipInfo)
      {%begin%}
        relationships = Hash(String, RelationshipInfo).new
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::Atlas::Relationship) %}
          {% if ann %}
            relationships[{{ivar.id.stringify}}] = RelationshipInfo.new(
              model: {{ann[:model]}}
            )
          {%end%}

        {% end %}

        relationships
      {%end%}
    end
  end

  macro preload(models, relation, model)
    {%begin%}
      {{models}}.each do |model|
        if x = {{@type}}.relationships[{{relation.stringify}}]
          model.{{relation.id}} = {{model}}.new(1, 1)
        end
      end
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

  macro has_one(name, model, keys)
    @[DB::Field(ignore: true)]
    @[Atlas::Relationship(type: :has_one, model: {{model}})]
    property {{name}} : {{model}} | Nil

    def self.preload_{{name}}(db, collection : Array({{@type}})) : Array({{@type}})
      {% base_id = keys.keys.first.id %}
      {% target_id = keys.keys.first.id %}
      target_id = {{keys.keys.first.stringify}}
      columns = {{model}}.columns.join(",")
      table = {{model}}.table
      in_values = collection.map_with_index { |_, i| "$#{i+1}"}.join(",")
      query = <<-SQL
        SELECT #{columns} from #{table} where #{target_id} in (#{in_values})
      SQL
      records = {{model}}.from_rs(db.query(query, args: collection.map(&.{{base_id}})))
      records.each do |record|
        x = collection.find! { |c| c.{{base_id}} == record.{{target_id}} }
        if x
          x.{{name}} = record
        end
      end
      collection
    end
  end
end
