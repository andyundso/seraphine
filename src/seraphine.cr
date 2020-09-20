require "./db"
require "./netdata"
require "./seraphine/background"
require "crest"
require "cryomongo"
require "kemal"
require "tasker"
require "totem"

module Seraphine
  VERSION = "0.1.0"

  client = Mongo::Client.new
  database = client["seraphine"]

  configuration = Totem.from_file "./netdata.yaml"
  polling_frequency = configuration.get("polling_frequency").as_i.seconds

  Tasker.in(5.seconds) { Seraphine::Background.new.enqueue }

  ws "/alarms" do |socket|
    loop do
      alarms = Hash(String, Array(JSON::Any)).new
      collections = database.command(Mongo::Commands::ListCollections, options: {nameOnly: true})

      if collections
        collections.cursor.first_batch.map do |collection_object|
          collection = DB::Collection.from_json(collection_object.to_json)
          alarms[collection.name] = database[collection.name].find(BSON.new).to_a.map { |bson_object| JSON.parse(bson_object.to_json) }
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
