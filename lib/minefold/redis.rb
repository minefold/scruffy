module Minefold
  module Redis
    def redis
      @redis ||= begin
        uri = URI.parse(REDIS_URI)
        ::Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      end
    end
  end
end