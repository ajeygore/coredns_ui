require 'rails_helper'

RSpec.describe "api_tokens/show", type: :view do
  before(:each) do
    assign(:api_token, ApiToken.create!(
      token: "Token",
      user: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Token/)
    expect(rendered).to match(//)
  end
end
