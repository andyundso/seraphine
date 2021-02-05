require "./logger"
require "kemal"

module Seraphine
  class Web
    property configuration : Totem::Config
    property database : Mongo::Database

    def initialize(logger : Seraphine::Logger, configuration : Totem::Config)
      Kemal.config.logger = logger
      @configuration = configuration
      @database = Mongo::Client.new(@configuration.get("database_url").as_s)[@configuration.get("database_name").as_s]
    end

    def run
      ws "/alarms" do |socket|
        polling_frequency = @configuration.get("polling_frequency").as_i.seconds

        loop do
          alarms = Hash(String, Array(JSON::Any)).new
          collections = @database.command(Mongo::Commands::ListCollections, options: {nameOnly: true})

          if collections
            collections.cursor.first_batch.map do |collection_object|
              collection = DB::Collection.from_json(collection_object.to_json)
              alarms[collection.name] = @database[collection.name].find(BSON.new).to_a.map { |bson_object| JSON.parse(bson_object.to_json) }
            end

            socket.send(alarms.to_json)
          end

          sleep polling_frequency
        end
      end

      Kemal.run do |config|
        server = config.server.not_nil!
        server.bind_tcp "0.0.0.0", 8000, reuse_port: true
      end
    end
  end
end
