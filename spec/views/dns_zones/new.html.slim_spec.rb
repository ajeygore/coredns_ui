require 'rails_helper'

RSpec.describe "dns_zones/new", type: :view do
  before(:each) do
    assign(:dns_zone, DnsZone.new(
      name: "MyString"
    ))
  end

  it "renders new dns_zone form" do
    render

    assert_select "form[action=?][method=?]", dns_zones_path, "post" do

      assert_select "input[name=?]", "dns_zone[name]"
    end
  end
end
