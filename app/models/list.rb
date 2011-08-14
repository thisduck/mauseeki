class List
  include MongoMapper::Document

  key :name, String
  key :saved, Boolean, :default => false
  key :clip_ids, Array
  key :order, Hash

  many :clips, :in => :clip_ids

  before_create :name_list

  def sorted_clips
    self.clips.sort do |a, b|
      a_index = (self.order[a.id.to_s] || self.clip_ids.index(a.id))
      b_index = (self.order[b.id.to_s] || self.clip_ids.index(b.id))
      a_index <=> b_index
    end
  end

  def order=(ids)
    count = 0
    ids.each do |id|
      self.order[id] = count
      count += 1
    end
  end

  protected

  def name_list
    self.name = "unnamed list: #{self.id}" if self.name.blank?
  end
end
