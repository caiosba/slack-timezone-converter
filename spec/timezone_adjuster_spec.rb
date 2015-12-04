require 'logger'
require_relative '../timezone_adjuster'

$log = Logger.new(STDOUT)
 
describe TimezoneAdjuster do
	describe '#get_list_for' do
		subject do 
			TimezoneAdjuster.new(:timezones => {'CST' => -21600})
		end
		let(:data) { {'type' => 'message', 'text' => '@time 12pm', 'user' => 'user'} }

		def get_list_for_user
			subject.get_list_for(:users => {'user' => { :tz => 'UTC', :offset => 0 }}, :data => data)
		end

		context 'when the notification is not a message' do
			let(:data) { super().merge('type' => 'not_message') }
			it { expect(get_list_for_user).to be_nil }
		end
		context 'when there isn\'t any message text' do
			let(:data) { super().merge('text' => nil) }
			it { expect(get_list_for_user).to be_nil }
		end
		context 'when the notification has a subtype' do
			let(:data) { super().merge('subtype' => 'subtype') }
			it { expect(get_list_for_user).to be_nil }
		end
		context 'when the notification has a reply_to in it' do
			let(:data) { super().merge('reply_to' => 'reply_to') }
			it { expect(get_list_for_user).to be_nil }
		end
		context 'when text doesn\'t contain "@time"' do
			let(:data) { super().merge('text' => '12pm') }
			it { expect(get_list_for_user).to be_nil }
		end
		context 'when text doesn\'t contain a time' do
			let(:data) { super().merge('text' => '@time') }
			it { expect(get_list_for_user).to be_nil }
		end
		context 'when there is one timezone' do
			it { expect(get_list_for_user).to eq(":clock12: 12:00 CST\n") }
		end
	end
end