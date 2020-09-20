require "kemal"

module Seraphine
  class Logger < Kemal::LogHandler
    def pretty_write(message : String)
      write("#{Time.utc} #{message}\n")
    end
  end
end
