require 'test_helper'

class RemotePayuLatamTest < Test::Unit::TestCase
  def setup
    @gateway = PayuLatamGateway.new(fixtures(:payu_latam).update(payment_country: 'AR'))
    @colombia_gateway = PayuLatamGateway.new(fixtures(:payu_latam).update(payment_country: 'CO', account_id: '512321'))

    @amount = 4000
    @credit_card = credit_card('4097440000000004', month: 6, year: 2035, verification_value: '777', first_name: 'APPROVED', last_name: '')
    @declined_card = credit_card('4097440000000004', verification_value: '777', first_name: 'REJECTED', last_name: '')
    @pending_card = credit_card('4097440000000004', verification_value: '777', first_name: 'PENDING', last_name: '')
    @naranja_credit_card = credit_card('5895620000000002', verification_value: '123', first_name: 'APPROVED', last_name: '', brand: 'naranja')
    @cabal_credit_card = credit_card('5896570000000004', verification_value: '123', first_name: 'APPROVED', last_name: '', brand: 'cabal')
    @invalid_cabal_card = credit_card('6271700000000000', verification_value: '123', first_name: 'APPROVED', last_name: '', brand: 'cabal')
    @condensa_card = credit_card('5907120000000009', month: 6, year: 2035, verification_value: '777', first_name: 'APPROVED', brand: 'condensa')

    @options = {
      dni_number: '5415668464654',
      merchant_buyer_id: '1',
      currency: 'ARS',
      order_id: generate_unique_id,
      description: 'Active Merchant Transaction',
      installments_number: 1,
      tax: 0,
      email: 'username@domain.com',
      ip: '127.0.0.1',
      device_session_id: 'vghs6tvkcle931686k1900o6e1',
      cookie: 'pt1t38347bs6jc9ruv2ecpv7o2',
      user_agent: 'Mozilla/5.0 (Windows NT 5.1; rv:18.0) Gecko/20100101 Firefox/18.0',
      billing_address: address(
        address1: 'Viamonte',
        address2: '1366',
        city: 'Plata',
        state: 'Buenos Aires',
        country: 'AR',
        zip: '64000',
        phone: '7563126'
      )
    }
  end

  # At the time of writing this test, gateway sandbox
  # supports auth and purchase transactions only

  def test_invalid_login
    gateway = PayuLatamGateway.new(merchant_id: '', account_id: '', api_login: 'U', api_key: 'U', payment_country: 'AR')
    response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_with_naranja_card
    response = @gateway.purchase(@amount, @naranja_credit_card, @options)
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_with_cabal_card
    response = @gateway.purchase(@amount, @cabal_credit_card, @options)
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_with_condensa_card
    response = @colombia_gateway.purchase(@amount, @condensa_card, @options.merge(currency: 'COP'))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_with_specified_language
    response = @gateway.purchase(@amount, @credit_card, @options.merge(language: 'es'))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_with_blank_billing_address_country
    response = @gateway.purchase(@amount, @credit_card, @options.merge(billing_address: { address1: 'Viamonte', country: '', zip: '10001' }))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_with_buyer
    gateway = PayuLatamGateway.new(fixtures(:payu_latam).update(account_id: '512327', payment_country: 'BR'))

    options_buyer = {
      currency: 'BRL',
      billing_address: address(
        address1: 'Calle 100',
        address2: 'BL4',
        city: 'Sao Paulo',
        state: 'SP',
        country: 'BR',
        zip: '09210710',
        phone: '(11)756312633'
      ),
      shipping_address: address(
        address1: 'Calle 200',
        address2: 'N107',
        city: 'Sao Paulo',
        state: 'SP',
        country: 'BR',
        zip: '01019-030',
        phone: '(11)756312633'
      ),
      buyer: {
        name: 'Jorge Borges',
        dni_number: '5415668464123',
        dni_type: 'TI',
        merchant_buyer_id: '2',
        cnpj: '32593371000110',
        email: 'axaxaxas@mlo.org'
      }
    }

    response = gateway.purchase(@amount, @credit_card, @options.update(options_buyer))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_brazil
    gateway = PayuLatamGateway.new(fixtures(:payu_latam).update(account_id: '512327', payment_country: 'BR'))

    options_brazil = {
      payment_country: 'BR',
      currency: 'BRL',
      billing_address: address(
        address1: 'Calle 100',
        address2: 'BL4',
        city: 'Sao Paulo',
        state: 'SP',
        country: 'BR',
        zip: '09210710',
        phone: '(11)756312633'
      ),
      shipping_address: address(
        address1: 'Calle 200',
        address2: 'N107',
        city: 'Sao Paulo',
        state: 'SP',
        country: 'BR',
        zip: '01019-030',
        phone: '(11)756312633'
      ),
      buyer: {
        cnpj: '32593371000110'
      }
    }

    response = gateway.purchase(@amount, @credit_card, @options.update(options_brazil))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_colombia
    gateway = PayuLatamGateway.new(fixtures(:payu_latam).update(account_id: '512321', payment_country: 'CO'))

    options_colombia = {
      payment_country: 'CO',
      currency: 'COP',
      billing_address: address(
        address1: 'Calle 100',
        address2: 'BL4',
        city: 'Bogota',
        state: 'Bogota DC',
        country: 'CO',
        zip: '09210710',
        phone: '(11)756312633'
      ),
      shipping_address: address(
        address1: 'Calle 200',
        address2: 'N107',
        city: 'Bogota',
        state: 'Bogota DC',
        country: 'CO',
        zip: '01019-030',
        phone: '(11)756312633'
      ),
      tax: '3193',
      tax_return_base: '16806'
    }

    response = gateway.purchase(2000000, @credit_card, @options.update(options_colombia))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_mexico
    gateway = PayuLatamGateway.new(fixtures(:payu_latam).update(account_id: '512324', payment_country: 'MX'))

    options_mexico = {
      payment_country: 'MX',
      currency: 'MXN',
      billing_address: address(
        address1: 'Calle 100',
        address2: 'BL4',
        city: 'Guadalajara',
        state: 'Jalisco',
        country: 'MX',
        zip: '09210710',
        phone: '(11)756312633'
      ),
      shipping_address: address(
        address1: 'Calle 200',
        address2: 'N107',
        city: 'Guadalajara',
        state: 'Jalisco',
        country: 'MX',
        zip: '01019-030',
        phone: '(11)756312633'
      ),
      birth_date: '1985-05-25'
    }

    response = gateway.purchase(@amount, @credit_card, @options.update(options_mexico))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_successful_purchase_no_description
    options = @options
    options.delete(:description)
    response = @gateway.purchase(@amount, @credit_card, options)
    assert_success response
    assert_equal 'APPROVED', response.message
    assert response.test?
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card)
    assert_failure response
    assert_equal 'DECLINED', response.params['transactionResponse']['state']
  end

  # Published API does not currently provide a way to request a CONTACT_THE_ENTITY
  # def test_failed_purchase_correct_message_when_payment_network_response_error_present
  #   response = @gateway.purchase(@amount, @credit_card, @options)
  #   assert_failure response
  #   assert_equal 'CONTACT_THE_ENTITY | Contactar con entidad emisora', response.message
  #   assert_equal 'Contactar con entidad emisora', response.params['transactionResponse']['paymentNetworkResponseErrorMessage']

  #   response = @gateway.purchase(@amount, @credit_card, @options)
  #   assert_failure response
  #   assert_equal 'CONTACT_THE_ENTITY', response.message
  #   assert_nil response.params['transactionResponse']['paymentNetworkResponseErrorMessage']
  # end

  def test_failed_purchase_with_cabal_card
    response = @gateway.purchase(@amount, @invalid_cabal_card, @options)
    assert_failure response
    assert_equal 'DECLINED', response.params['transactionResponse']['state']
  end

  def test_failed_purchase_with_no_options
    response = @gateway.purchase(@amount, @declined_card, {})
    assert_failure response
    assert_equal 'DECLINED', response.params['transactionResponse']['state']
  end

  def test_failed_purchase_with_specified_language
    gateway = PayuLatamGateway.new(merchant_id: '', account_id: '', api_login: 'U', api_key: 'U', payment_country: 'AR')
    response = gateway.purchase(@amount, @declined_card, @options.merge(language: 'es'))
    assert_failure response
    assert_equal 'Credenciales inválidas', response.message
  end

  def test_successful_authorize
    response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'APPROVED', response.message
    assert_match %r(^\d+\|(\w|-)+$), response.authorization
  end

  def test_successful_authorize_with_naranja_card
    response = @gateway.authorize(@amount, @naranja_credit_card, @options)
    assert_success response
    assert_equal 'APPROVED', response.message
    assert_match %r(^\d+\|(\w|-)+$), response.authorization
  end

  def test_successful_authorize_with_cabal_card
    response = @gateway.authorize(@amount, @cabal_credit_card, @options)
    assert_success response
    assert_equal 'APPROVED', response.message
    assert_match %r(^\d+\|(\w|-)+$), response.authorization
  end

  def test_successful_authorize_with_specified_language
    response = @gateway.authorize(@amount, @credit_card, @options.merge(language: 'es'))
    assert_success response
    assert_equal 'APPROVED', response.message
    assert_match %r(^\d+\|(\w|-)+$), response.authorization
  end

  def test_failed_authorize
    response = @gateway.authorize(@amount, @declined_card)
    assert_failure response
    assert_equal 'DECLINED', response.params['transactionResponse']['state']
  end

  def test_failed_authorize_with_specified_language
    gateway = PayuLatamGateway.new(merchant_id: '', account_id: '', api_login: 'U', api_key: 'U', payment_country: 'AR')
    response = gateway.authorize(@amount, @pending_card, @options.merge(language: 'es'))
    assert_failure response
    assert_equal 'Credenciales inválidas', response.message
  end

  # As noted above, capture transactions are currently not supported, but in the hope
  # they will one day be, here you go

  # def test_successful_capture
  #   response = @gateway.authorize(@amount, @credit_card, @options)
  #   assert_success response
  #   assert_equal 'APPROVED', response.message
  #   assert_match %r(^\d+\|(\w|-)+$), response.authorization

  #   capture = @gateway.capture(@amount, response.authorization, @options)
  #   assert_success capture
  #   assert_equal 'APPROVED', response.message
  #   assert response.test?
  # end

  # def test_successful_partial_capture
  #   response = @gateway.authorize(@amount, @credit_card, @options)
  #   assert_success response
  #   assert_equal 'APPROVED', response.message
  #   assert_match %r(^\d+\|(\w|-)+$), response.authorization

  #   capture = @gateway.capture(@amount - 1, response.authorization, @options)
  #   assert_success capture
  #   assert_equal 'APPROVED', response.message
  #   assert_equal '39.99', response.params['TX_VALUE']['value']
  #   assert response.test?
  # end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    assert refund = @gateway.refund(@amount, purchase.authorization, @options)
    assert_success refund
    assert_equal 'APPROVED', refund.message
  end

  def test_failed_refund
    response = @gateway.refund(@amount, '')
    assert_failure response
    assert_match(/property: parentTransactionId, message: must not be null/, response.message)
  end

  def test_failed_refund_with_specified_language
    response = @gateway.refund(@amount, '', language: 'es')
    assert_failure response
    assert_match(/property: parentTransactionId, message: No puede ser vacio/, response.message)
  end

  def test_failed_void
    response = @gateway.void('')
    assert_failure response
    assert_match(/property: parentTransactionId, message: must not be null/, response.message)
  end

  def test_failed_void_with_specified_language
    response = @gateway.void('', language: 'es')
    assert_failure response
    assert_match(/property: parentTransactionId, message: No puede ser vacio/, response.message)
  end

  def test_failed_capture
    response = @gateway.capture(@amount, '')
    assert_failure response
    assert_match(/must not be null/, response.message)
  end

  def test_verify_credentials
    assert @gateway.verify_credentials

    gateway = PayuLatamGateway.new(merchant_id: 'X', account_id: '512322', api_login: 'X', api_key: 'X', payment_country: 'AR')
    assert !gateway.verify_credentials
  end

  def test_successful_verify
    verify = @gateway.verify(@credit_card, @options)

    assert_success verify
    assert_equal 'APPROVED', verify.message
  end

  def test_successful_verify_with_specified_amount
    verify = @gateway.verify(@credit_card, @options.merge(verify_amount: 5100))

    assert_success verify
    assert_equal 'APPROVED', verify.message
  end

  def test_successful_verify_with_specified_language
    verify = @gateway.verify(@credit_card, @options.merge(language: 'es'))

    assert_success verify
    assert_equal 'APPROVED', verify.message
  end

  def test_failed_verify_with_specified_amount
    verify = @gateway.verify(@credit_card, @options.merge(verify_amount: 499))

    assert_failure verify
    assert_equal 'INVALID_TRANSACTION | [The given payment value [4.99] is inferior than minimum configured value [5]]', verify.message
  end

  def test_failed_verify_with_specified_language
    verify = @gateway.verify(@credit_card, @options.merge(verify_amount: 499, language: 'es'))

    assert_failure verify
    assert_equal 'INVALID_TRANSACTION | [El valor recibido [4,99] es inferior al valor mínimo configurado [5]]', verify.message
  end

  def test_transcript_scrubbing
    transcript = capture_transcript(@gateway) do
      @gateway.purchase(@amount, @credit_card, @options)
    end
    clean_transcript = @gateway.scrub(transcript)

    assert_scrubbed(@credit_card.number, clean_transcript)
    assert_scrubbed(@credit_card.verification_value.to_s, clean_transcript)
    assert_scrubbed(@gateway.options[:api_key], clean_transcript)
  end

  def test_successful_store
    store = @gateway.store(@credit_card, @options)
    assert_success store
    assert_equal 'SUCCESS', store.message
  end
end
