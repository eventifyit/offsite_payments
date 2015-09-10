require 'test_helper'

class XpayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Xpay::Helper.new('order-500', 'merchant-id', amount: 500,
                               currency: 'USD', return_url: 'example.com',
                               api_key: 'APIKEY')
    @helper.language 'en'
    @helper.email 'email@example.com'
    @helper.cancel_url 'back.com'

  end

  def test_basic_helper_fields
    assert_field 'codTrans', 'order-500'
    assert_field 'alias', 'merchant-id'
    assert_field 'importo', '500'
    assert_field 'url', 'example.com'
  end

  def test_service_extra_fields
    assert_field 'languageId', 'en'
    assert_field 'mail', 'email@example.com'
    assert_field 'url_back', 'back.com'
  end

  def test_transaction_checksum
    assert_equal(
      @helper.transaction_checksum,
      'd9a61fa6202e2e02f8497f51fa0a6b893a78212f'
    )
  end
end
