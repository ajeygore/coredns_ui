require 'rails_helper'

RSpec.describe 'dns_zones/index', type: :view do
  before(:each) do
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
    cell_selector = Rails::VERSION::STRING >= '7' ? 'tbody' : 'tr>td'
    assert_select cell_selector, text: Regexp.new('Name'.to_s), count: 1
  end
end
