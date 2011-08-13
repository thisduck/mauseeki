class List
  include MongoMapper::Document

  key :saved, Boolean, :default => false
  key :clip_ids, Array

  many :clips, :in => :clip_ids
end
