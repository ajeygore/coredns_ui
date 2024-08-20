require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/api_tokens", type: :request do
  # This should return the minimal set of attributes required to create a valid
  # ApiToken. As you add validations to ApiToken, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  describe "GET /index" do
    it "renders a successful response" do
      ApiToken.create! valid_attributes
      get api_tokens_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      api_token = ApiToken.create! valid_attributes
      get api_token_url(api_token)
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      api_token = ApiToken.create! valid_attributes
      get edit_api_token_url(api_token)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ApiToken" do
        expect {
          post api_tokens_url, params: { api_token: valid_attributes }
        }.to change(ApiToken, :count).by(1)
      end

      it "redirects to the created api_token" do
        post api_tokens_url, params: { api_token: valid_attributes }
        expect(response).to redirect_to(api_token_url(ApiToken.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new ApiToken" do
        expect {
          post api_tokens_url, params: { api_token: invalid_attributes }
        }.to change(ApiToken, :count).by(0)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post api_tokens_url, params: { api_token: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested api_token" do
        api_token = ApiToken.create! valid_attributes
        patch api_token_url(api_token), params: { api_token: new_attributes }
        api_token.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the api_token" do
        api_token = ApiToken.create! valid_attributes
        patch api_token_url(api_token), params: { api_token: new_attributes }
        api_token.reload
        expect(response).to redirect_to(api_token_url(api_token))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        api_token = ApiToken.create! valid_attributes
        patch api_token_url(api_token), params: { api_token: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested api_token" do
      api_token = ApiToken.create! valid_attributes
      expect {
        delete api_token_url(api_token)
      }.to change(ApiToken, :count).by(-1)
    end

    it "redirects to the api_tokens list" do
      api_token = ApiToken.create! valid_attributes
      delete api_token_url(api_token)
      expect(response).to redirect_to(api_tokens_url)
    end
  end
end
