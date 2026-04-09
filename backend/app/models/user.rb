class User < ApplicationRecord
  has_many :conversions, dependent: :destroy

  before_validation :normalize_email
  before_validation :ensure_api_key_token

  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :api_key_digest, presence: true, uniqueness: true
  validates :api_key_token, presence: true, uniqueness: true

  def ensure_api_key!
    return api_key_token if api_key_token.present? && api_key_digest.present?

    rotate_api_key!
  end

  def rotate_api_key!
    plaintext = self.class.generate_api_key
    update!(
      api_key_token: plaintext,
      api_key_digest: self.class.digest_api_key(plaintext)
    )
    plaintext
  end

  def api_key_configured?
    api_key_digest.present?
  end

  def self.find_by_api_key(api_key)
    return if api_key.blank?

    find_by(api_key_digest: digest_api_key(api_key))
  end

  def self.digest_api_key(api_key)
    Digest::SHA256.hexdigest(api_key)
  end

  def self.generate_api_key
    "bsc_#{SecureRandom.hex(24)}"
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def ensure_api_key_token
    return if self[:api_key_token].present? && self[:api_key_digest].present?

    plaintext = self.class.generate_api_key
    self[:api_key_token] = plaintext
    self[:api_key_digest] = self.class.digest_api_key(plaintext)
  end
end
