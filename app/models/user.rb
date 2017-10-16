class User < ApplicationRecord
  has_many :votes
  has_many :ranked_works, through: :votes, source: :work
  has_many :works, dependent: :nullify

  validates :username, uniqueness: true, presence: true
end
