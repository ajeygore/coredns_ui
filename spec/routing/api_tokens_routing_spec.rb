require "rails_helper"

RSpec.describe ApiTokensController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api_tokens").to route_to("api_tokens#index")
    end

    it "routes to #new" do
      expect(get: "/api_tokens/new").to route_to("api_tokens#new")
    end
  end
end
