require 'rails_helper'

RSpec.describe "dns_zones/edit", type: :view do
  let(:dns_zone) {
    DnsZone.create!(
      name: "MyString"
    )
  }

  before(:each) do
    assign(:dns_zone, dns_zone)
  end

  it "renders the edit dns_zone form" do
    render

    assert_select "form[action=?][method=?]", dns_zone_path(dns_zone), "post" do

      assert_select "input[name=?]", "dns_zone[name]"
    end
  end
end
