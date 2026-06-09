class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable

  has_many :metrics, dependent: :destroy

  before_create :ensure_api_token

  def rotate_api_token!
    update!(api_token: self.class.generate_api_token)
  end

  def self.generate_api_token
    SecureRandom.urlsafe_base64(32)
  end

  private

  def ensure_api_token
    self.api_token ||= self.class.generate_api_token
  end
end
