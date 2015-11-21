require_relative '../timezone_adjuster'
 
describe TimezoneAdjuster do
	describe '#get_list_for' do
		subject do 
			TimezoneAdjuster.new(:current_user => nil, 
								 :timezones => nil, 
								 :prepended_message => nil)
		end
		let(:data) { {'type' => 'message', 'text' => 'text'} }

		def get_list_for_nil
			subject.get_list_for(:users => nil, :data => data)
		end

		context 'when data type is not message' do
			let(:data) { super().merge('type' => 'not_message')}
			it { expect(get_list_for_nil).to be_nil }
		end
		context 'when data text is nil' do
			let(:data) { super().merge('text' => nil)}
			it { expect(get_list_for_nil).to be_nil }
		end
	end
end