require 'rails_helper'

RSpec.describe "api_tokens/edit", type: :view do
  let(:api_token) {
    ApiToken.create!(
      token: "MyString",
      user: nil
    )
  }

  before(:each) do
    assign(:api_token, api_token)
  end

  it "renders the edit api_token form" do
    render

    assert_select "form[action=?][method=?]", api_token_path(api_token), "post" do

      assert_select "input[name=?]", "api_token[token]"

      assert_select "input[name=?]", "api_token[user_id]"
    end
  end
end
