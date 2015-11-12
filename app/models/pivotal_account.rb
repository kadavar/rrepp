class PivotalAccount < ActiveRecord::Base

  has_many :projects

  validates :tracker_token,  uniqueness: true, presence: true
  validates :name , presence: true

end
