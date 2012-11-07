ROOT = File.expand_path "../..", __FILE__

EC2_SECRET_KEY="4VI8OqUBN6LSDP6cAWXUo0FM1L/uURRGIGyQCxvq"
EC2_ACCESS_KEY="AKIAJPN5IJVEBB2QE35A"
MONGOHQ_URL='mongodb://localhost/'
REDIS_URI="redis://localhost:6379/"

Fold.workers = :local
Fold.worker_user = ENV['USER']

StatsD.logger = Logger.new(STDOUT) #Logger.new('/dev/null')
StatsD.mode = :development

# ENV['RACK_ENV'] = 'production' # exceptional gem looks at this ENV
# Exceptional::Config.load("#{ROOT}/config/exceptional.yml")

TEST_PRISM="localhost"