require "json"

module Netdata
  class Info
    include JSON::Serializable
    
    @[JSON::Field(key: mirrored_hosts)]
    property mirrored_hosts : Array(String)
  end

  module Alarm
    class Info
      include JSON::Serializable

      @[JSON::Field(key: alarms)]
      property alarms : Hash(String, JSON::Any)
    end

    class Detail
      include JSON::Serializable

      @[JSON::Field(key: name)]
      property name : String

      @[JSON::Field(key: last_status_change)]
      property last_raised : Int32

      @[JSON::Field(key: value_string)]
      property value : String

      def to_h
        {
          name: name,
          last_raised: last_raised,
          value: value
        }
      end
    end
  end
end
