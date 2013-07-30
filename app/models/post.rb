class Post < ActiveRecord::Base
  belongs_to :user
  has_many :collaborations
  has_many :collaborators, through: :collaborations, source: :user

  scope :created_by, -> (user_id) { where(user_id: user_id) }
  scope :reverse_chronological_order, -> { order(:id) }
  scope :with_collaborators, -> { where("EXISTS (SELECT * FROM collaborations WHERE collaborations.post_id = posts.id)") }

  validates_presence_of :title, :content

  attr_accessor :collaborator_emails

  def collaborator_emails=(emails)
    collaborators = User.where(email: emails)
    self.collaborations = collaborators.map do |collaborator|
      Collaboration.new(user: collaborator, post: self)
    end
    emails
  end
end
