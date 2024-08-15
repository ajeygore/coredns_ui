require 'rails_helper'

RSpec.describe "dns_zones/show", type: :view do
  before(:each) do
    assign(:dns_zone, DnsZone.create!(
      name: "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
  end
end
