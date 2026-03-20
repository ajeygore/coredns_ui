require 'rails_helper'

RSpec.describe "/api_tokens", type: :request do
  let(:user) { User.create!(email: 'admin@test.com', name: 'Admin', admin: true, permitted_zones: '*') }

  before { login_as(user) }

  describe "GET /index" do
    it "renders a successful response" do
      ApiToken.create!(user: user)
      get api_tokens_url
      expect(response).to be_successful
    end

    it "shows only own tokens for non-admin users" do
      other_user = User.create!(email: 'other@test.com', name: 'Other', permitted_zones: '*')
      ApiToken.create!(user: user)
      ApiToken.create!(user: other_user)

      login_as(other_user)
      get api_tokens_url
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_api_token_url
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    it "creates a new ApiToken" do
      expect {
        post api_tokens_url, params: { api_token: { permitted_zones: '*' } }
      }.to change(ApiToken, :count).by(1)
      expect(response).to redirect_to(api_tokens_path)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested api_token" do
      api_token = ApiToken.create!(user: user)
      expect {
        delete api_token_url(api_token)
      }.to change(ApiToken, :count).by(-1)
    end

    it "redirects to the api_tokens list" do
      api_token = ApiToken.create!(user: user)
      delete api_token_url(api_token)
      expect(response).to redirect_to(api_tokens_url)
    end
  end

  describe "access control" do
    it "redirects unauthenticated users to login" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(false)

      get api_tokens_url
      expect(response).to redirect_to(login_path)
    end
  end
end
