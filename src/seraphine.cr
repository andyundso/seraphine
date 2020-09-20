require "./db"
require "./netdata"
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
  netdata_servers = configuration.get("servers").as_a
  polling_frequency = configuration.get("polling_frequency").as_i.seconds

  netdata_servers.each do |netdata_server|
    Tasker.every(polling_frequency) do
      http_client = Crest::Resource.new(
       netdata_server.as_h["url"].as_s,
       auth: "basic",
       user: netdata_server.as_h["username"].as_s,
       password: netdata_server.as_h["password"].as_s
      )

      response = Netdata::Info.from_json(http_client["/api/v1/info"].get.body)

      response.mirrored_hosts.each do |mirrored_host|
        collection = database[mirrored_host]
        collection.delete_many(BSON.new)
        response = Netdata::Alarm::Info.from_json(http_client["/host/#{mirrored_host}/api/v1/alarms"].get.body)
        response.alarms.each do |alarm_name, alarm_values|
          collection.insert_one(Netdata::Alarm::Detail.from_json(alarm_values.to_json).to_h)
        end
      end
    end

    Tasker.every(1.hour) do
      database.command(Mongo::Commands::DropDatabase)
    end
  end

  ws "/alarms" do |socket|
    loop do
      alarms = Hash(String, Array(JSON::Any)).new
      collections = database.command(Mongo::Commands::ListCollections, options: { nameOnly: true })

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
