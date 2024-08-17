require 'rails_helper'

RSpec.describe "api_tokens/new", type: :view do
  before(:each) do
    assign(:api_token, ApiToken.new(
      token: "MyString",
      user: nil
    ))
  end

  it "renders new api_token form" do
    render

    assert_select "form[action=?][method=?]", api_tokens_path, "post" do

      assert_select "input[name=?]", "api_token[token]"

      assert_select "input[name=?]", "api_token[user_id]"
    end
  end
end
