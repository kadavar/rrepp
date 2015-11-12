class PivotalAccount < ActiveRecord::Base
  validates :tracker_token,  uniqueness: true, presence: true
  validates :name , presence: true

end
