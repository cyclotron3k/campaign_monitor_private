require "test_helper"

class CampaignMonitorPrivateTest < Minitest::Test
	def test_that_it_has_a_version_number
		refute_nil ::CampaignMonitorPrivate::VERSION
	end

	def test_initialization
		e = assert_raises(ArgumentError) do
			CampaignMonitorPrivate.new
		end
		assert_equal 'No username provided', e.message

		e = assert_raises(ArgumentError) do
			CampaignMonitorPrivate.new username: ''
		end
		assert_equal 'No password provided', e.message
	end

end
