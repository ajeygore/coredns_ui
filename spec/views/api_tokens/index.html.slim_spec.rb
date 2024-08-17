require 'rails_helper'

RSpec.describe "api_tokens/index", type: :view do
  before(:each) do
    assign(:api_tokens, [
      ApiToken.create!(
        token: "Token",
        user: nil
      ),
      ApiToken.create!(
        token: "Token",
        user: nil
      )
    ])
  end

  it "renders a list of api_tokens" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Token".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
