if ENV['MONGOLAB_URI']
  MongoMapper.config = {Rails.env => {'uri' => ENV['MONGOLAB_URI']}}
  MongoMapper.connect(Rails.env)
else
  logger = ENV['LOG_MONGO'] ? Rails.logger : nil
  MongoMapper.connection = Mongo::Connection.new('localhost', 27017, :logger => logger)
  MongoMapper.database  = "mdot_#{Rails.env}"
end
