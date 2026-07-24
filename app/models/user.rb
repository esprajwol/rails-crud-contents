# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :contents, dependent: :destroy

  # Invalidate the Redis user-auth cache whenever the record changes or is removed.
  # This prevents stale cached user objects from being returned after an update/delete.
  after_update_commit  :invalidate_auth_cache
  after_destroy_commit :invalidate_auth_cache

  # Normalize email to lowercase before saving
  before_save :downcase_email

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # Virtual attribute: full name (not stored in DB)
  def name
    "#{first_name} #{last_name}"
  end

  private

  def downcase_email
    self.email = email.downcase
  end

  # Deletes this user's entry from the auth cache.
  # Key must match the pattern in Authenticatable#user_cache_key.
  def invalidate_auth_cache
    Rails.cache.delete("user_auth:#{id}")
  end
end
