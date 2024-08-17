require "rails_helper"

RSpec.describe ApiTokensController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api_tokens").to route_to("api_tokens#index")
    end

    it "routes to #new" do
      expect(get: "/api_tokens/new").to route_to("api_tokens#new")
    end

    it "routes to #show" do
      expect(get: "/api_tokens/1").to route_to("api_tokens#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/api_tokens/1/edit").to route_to("api_tokens#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/api_tokens").to route_to("api_tokens#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/api_tokens/1").to route_to("api_tokens#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/api_tokens/1").to route_to("api_tokens#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/api_tokens/1").to route_to("api_tokens#destroy", id: "1")
    end
  end
end
