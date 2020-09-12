require "./netdata"
require "crest"
require "cryomongo"
require "kemal"
require "tasker"
require "totem"

module NetdataDashboard
  VERSION = "0.1.0"

  client = Mongo::Client.new
  database = client["seraphine"]
  configuration = Totem.from_file "./netdata.yaml"
  netdata_servers = configuration.get("servers").as_a

  netdata_servers.each do |netdata_server|
    task = Tasker.every((configuration.get("polling_frequency").as_i).seconds) do
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
  end

  ws "/alarms" do |socket|
  end

  Kemal.run do |config|
    server = config.server.not_nil!
    server.bind_tcp "0.0.0.0", 8000, reuse_port: true
  end
end
