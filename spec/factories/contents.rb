# frozen_string_literal: true

FactoryBot.define do
  factory :content do
    title { Faker::Lorem.sentence(word_count: 4) }
    body  { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    association :user
  end
end
