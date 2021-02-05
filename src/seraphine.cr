require "./db"
require "./netdata"
require "./seraphine/background"
require "./seraphine/logger"
require "./seraphine/web"
require "tasker"
require "totem"

module Seraphine
  configuration = Totem.from_file(ENV["CONFIG_FILE"] ||= "./seraphine.yaml")

  seraphine_logger = Seraphine::Logger.new
  Tasker.in(5.seconds) { Seraphine::Background.new(seraphine_logger, configuration).enqueue }
  Seraphine::Web.new(seraphine_logger, configuration).run
end
