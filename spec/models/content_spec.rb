# frozen_string_literal: true

require "rails_helper"

RSpec.describe Content, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
  end

  describe "dependent destroy" do
    it "destroys associated contents when user is destroyed" do
      user = create(:user)
      create(:content, user: user)
      expect { user.destroy }.to change(Content, :count).by(-1)
    end
  end
end
