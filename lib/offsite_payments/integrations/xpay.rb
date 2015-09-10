module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Xpay

      mattr_accessor :service_url
      self.service_url = 'https://ecommerce.keyclient.it/ecomm/ecomm/DispatcherServlet'

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper
        # Prepare the request to be sent to the gateway to initialize
        # the payment process.

        # The api_key should be passed to the class to generate the mac.
        # Removing it before calling super avoids the check on the
        # passed parameters that happens during the initialize method
        # of the ancestor Helper class.
        def initialize(order, account, options = {})
          @api_key = options.delete(:api_key)
          super
        end

        LANGUAGE_CODES = {
          it: 'ITA',
          en: 'ENG',
          es: 'SPA',
          fr: 'FRA',
          de: 'GER',
          jp: 'JPN'
        }

        mapping :order,     'codTrans'
        mapping :account,   'alias'
        mapping :amount,    'importo'
        mapping :currency,  'divisa'
        mapping :language,  'languageId'
        mapping :email,     'mail'

        mapping :return_url, 'url'
        mapping :cancel_url, 'url_back'

        def form_fields
          @fields['mac'] = transaction_checksum
          @fields['languageId'] = xpay_language_code
          @fields
        end

        def transaction_checksum
          params = {
            codTrans:  @fields['codTrans'],
            divisa:    @fields['divisa'],
            importo:   @fields['importo'],
          }.each_with_object('') do |(k, v), string|
            string << "#{k}=#{v}"
          end

          Digest::SHA1.hexdigest(params + api_key)
        end

        def form_method
          "GET"
        end

        private

        attr_reader :api_key

        def xpay_language_code
          LANGUAGE_CODES[@fields['languageId'].to_sym] || LANGUAGE_CODES[:en]
        end

        def gateway_key
          ENV['XPAY_GATEWAY_KEY'] || raise('XPAY_GATEWAY_KEY not set!')
        end
      end

      class Notification < OffsitePayments::Notification
        def initialize(params, options = {})
          @params = params
          @options = options
        end

        def complete?
          params['esito'] == 'OK'
        end

        def transaction_id
          params['codTrans']
        end

        def received_at
          received_at_datetime
        end

        def payer_name
          params['nome']
        end

        def payer_surname
          params['cognome']
        end

        def payer_email
          params['email']
        end

        def authorization_code
          params['codAut']
        end

        def gross
          params['importo']
        end

        def amount
          Money.new(params['importo'], params['divisa'])
        end

        def test?
          return false
        end

        def status
          params['esito']
        end

        # Acknowledge the transaction to XPay.
        #
        # This method has to be called after a new notification
        # arrives to verify that all the information received
        # are correct.
        def acknowledge(authcode = nil)
          valid_checksum && complete?
        end

        def transaction_confirmation_checksum
          verification = params
            .slice('codTrans', 'esito', 'importo',
                   'divisa', 'data', 'orario', 'codAut')
            .each_with_object('') do |(k, v), string|
              string << "#{k}=#{v}"
            end

          Digest::SHA1.hexdigest(verification + options[:key])
        end

        private

        attr_reader :params, :options

        def received_at_datetime
          DateTime.strptime(params['data'] + params['orario'], '%Y%m%d%H%M%S')
        end

        def valid_checksum
          params['mac'] == transaction_confirmation_checksum
        end
      end
    end
  end
end
