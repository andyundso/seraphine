require "json"

module DB
  class Collection
    include JSON::Serializable
    
    @[JSON::Field(key: name)]
    property name : String
  end
end
