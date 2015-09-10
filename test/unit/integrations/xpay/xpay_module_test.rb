require 'test_helper'

class XpayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Xpay::Notification, Xpay.notification('name=cody')
  end
end
