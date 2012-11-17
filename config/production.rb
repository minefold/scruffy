ROOT = File.expand_path "../..", __FILE__

# TODO: put these somewhere more secure
EC2_SECRET_KEY="4VI8OqUBN6LSDP6cAWXUo0FM1L/uURRGIGyQCxvq"
EC2_ACCESS_KEY="AKIAJPN5IJVEBB2QE35A"
MONGOHQ_URL="mongodb://minefold:Aru06kAy8xE2@sun.member0.mongohq.com:10018/production,minefold:Aru06kAy8xE2@sun.member1.mongohq.com:10018/production"
REDIS_URI="redis://redis:0128df27dcecc0dac569b231d5bd7ccb@ec2-184-72-137-163.compute-1.amazonaws.com:9097/"

uri = URI.parse(REDIS_URI)
Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

SSH_PRIVATE_KEY_PATH=ENV['EC2_SSH'] || "#{ROOT}/.ec2/east/minefold2.pem"

StatsD.server = 'stats.minefold.com:8125'
StatsD.logger = Logger.new('/dev/null')
StatsD.mode = :production

ENV['RACK_ENV'] = 'production' # exceptional gem looks at this ENV
Exceptional::Config.load("#{ROOT}/config/exceptional.yml")

TEST_PRISM="pluto.minefold.com"