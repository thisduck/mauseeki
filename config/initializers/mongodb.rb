if ENV['MONGOLAB_URI']
  MongoMapper.config = {RAILS_ENV => {'uri' => ENV['MONGOHQ_URL']}}
  MongoMapper.connect(RAILS_ENV)
else
  logger = ENV['LOG_MONGO'] ? Rails.logger : nil
  MongoMapper.connection = Mongo::Connection.new('localhost', 27017, :logger => logger)
  MongoMapper.database  = "mdot_#{Rails.env}"
end
