require 'test_helper'

class XpayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @xpay = Xpay::Notification.new(
      params,
      { key: '234558767876' }
    )
  end

  def test_accessors
    assert_equal 'OK', @xpay.status
    assert_equal 'f795b112', @xpay.transaction_id
    assert_equal '24400', @xpay.gross
    assert @xpay.complete?
    assert_false @xpay.test?
  end

  def test_amount
    assert_equal Money.new(24400, 'EUR'), @xpay.amount
  end

  def test_received_at
    assert_equal(
      DateTime.parse('Thu, 10 Sep 2015 14:24:23 +0000'),
      @xpay.received_at
    )
  end

  def test_acknowledgement_false
    assert_false @xpay.acknowledge
  end

  def test_transaction_checksum
    assert_equal(
      'ccc931dfde713cca4b6a12b1f52f295ff2d16cbe',
      @xpay.transaction_confirmation_checksum
    )
  end

  def test_respond_to_acknowledge
    assert @xpay.respond_to?(:acknowledge)
  end

  private
  def params
    Rack::Utils.parse_nested_query "alias=payment_444994&codTrans=f795b112&divisa=EUR&importo=24400&data=20150910&orario=142423&esito=OK&codAut=TESTOKesempiodicalcolomac&mac=d9a61fa6202e2e02f8497f51fa0a6b893a78212f"
  end
end
