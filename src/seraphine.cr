require "./db"
require "./netdata"
require "./seraphine/background"
require "./seraphine/logger"
require "./seraphine/web"
require "tasker"

module Seraphine
  VERSION = "0.1.0"

  seraphine_logger = Seraphine::Logger.new
  Tasker.in(5.seconds) { Seraphine::Background.new(seraphine_logger).enqueue }
  Seraphine::Web.new(seraphine_logger).run
end
