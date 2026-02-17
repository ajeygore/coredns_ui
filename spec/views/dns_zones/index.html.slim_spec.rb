require 'rails_helper'

RSpec.describe 'dns_zones/index', type: :view do
  before(:each) do
    user = User.create!(email: 'test@example.com', name: 'Test', admin: true, permitted: true)
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
    end

    assign(:dns_zones, [
             DnsZone.create!(
               name: 'Name'
             ),
             DnsZone.create!(
               name: 'Name1'
             )
           ])
  end

  it 'renders a list of dns_zones' do
    render
    assert_select '.zone-item', count: 2
  end
end
