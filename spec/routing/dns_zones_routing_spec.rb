require "rails_helper"

RSpec.describe DnsZonesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/dns_zones").to route_to("dns_zones#index")
    end

    it "routes to #new" do
      expect(get: "/dns_zones/new").to route_to("dns_zones#new")
    end

    it "routes to #show" do
      expect(get: "/dns_zones/1").to route_to("dns_zones#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/dns_zones/1/edit").to route_to("dns_zones#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/dns_zones").to route_to("dns_zones#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/dns_zones/1").to route_to("dns_zones#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/dns_zones/1").to route_to("dns_zones#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/dns_zones/1").to route_to("dns_zones#destroy", id: "1")
    end
  end
end
