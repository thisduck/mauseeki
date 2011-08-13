class List
  include MongoMapper::Document

  key :name, String
  key :saved, Boolean, :default => false
  key :clip_ids, Array

  many :clips, :in => :clip_ids

  before_create :name_list

  protected

  def name_list
    self.name = "unnamed list: #{self.id}" if self.name.blank?
  end
end
