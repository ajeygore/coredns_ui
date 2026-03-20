require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /logout" do
    it "clears session and redirects to login" do
      user = User.create!(email: 'test@example.com', name: 'Test', permitted: true)
      login_as(user)

      get logout_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /login" do
    it "renders the login page for unauthenticated users" do
      get login_path
      expect(response).to be_successful
    end

    it "redirects authenticated users to zones" do
      user = User.create!(email: 'test@example.com', name: 'Test', permitted: true)
      login_as(user)

      get login_path
      expect(response).to redirect_to(dns_zones_path)
    end
  end
end
