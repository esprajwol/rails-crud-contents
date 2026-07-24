# frozen_string_literal: true

class Content < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :body,  presence: true
end
