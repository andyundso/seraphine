require "./logger"
require "halite"
require "cryomongo"
require "future"
require "tasker"
require "totem"

module Seraphine
  class Background
    property configuration : Totem::Config
    property database : Mongo::Database
    property logger : Seraphine::Logger

    def initialize(logger : Seraphine::Logger, configuration : Totem::Config)
      @configuration = configuration
      @database = Mongo::Client.new(@configuration.get("database_url").as_s)[@configuration.get("database_name").as_s]
      @logger = logger
    end

    def enqueue
      netdata_servers = configuration.get("servers").as_a
      
      netdata_servers.each do |netdata_server|
        get_alarms_for_host(netdata_server)
      end

      drop_database_job
    end

    private def drop_database_job
      task = Tasker.every(1.hour) do
        @logger.pretty_write("Started dropping database.")
        @database.command(Mongo::Commands::DropDatabase)
        @logger.pretty_write("Finished dropping database.")
      end

      task.get
    end

    private def get_alarms_for_host(netdata_server)
      task = Tasker.every(@configuration.get("polling_frequency").as_i.seconds) do
        netdata_server_url = netdata_server.as_h["url"].as_s

        @logger.pretty_write("Started fetching information for #{netdata_server_url}")

        http_client = client = Halite::Client.new do
          basic_auth netdata_server.as_h["username"].as_s, netdata_server.as_h["password"].as_s
          endpoint netdata_server_url
        end

        response = Netdata::Info.from_json(http_client.get("/api/v1/info").body)

        response.mirrored_hosts.each do |mirrored_host|
          collection = @database[mirrored_host]
          collection.delete_many(BSON.new)
          
          @logger.pretty_write("Started fetching information for #{mirrored_host} on #{netdata_server_url}")
          
          response = Netdata::Alarm::Info.from_json(http_client.get("/host/#{mirrored_host}/api/v1/alarms").body)
          response.alarms.each do |alarm_name, alarm_values|
            collection.insert_one(Netdata::Alarm::Detail.from_json(alarm_values.to_json).to_h)
          end
          
          @logger.pretty_write("Finished fetching information for #{mirrored_host} on #{netdata_server_url}")
        end

        @logger.pretty_write("Finished fetching information for #{netdata_server_url}")
      end

      task.get
    end
  end
end
