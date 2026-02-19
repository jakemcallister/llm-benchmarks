# frozen_string_literal: true

class KeywordDelegationProxyTest < Minitest::Test
  def setup
    @client = BillingClient.new
    @proxy = KeywordDelegationProxy.new(@client)
    @nested_proxy = KeywordDelegationProxy.new(@proxy)
    @retry_proxy = RetryProxy.new(@client)
    @instrumented_client = InstrumentedBillingClient.new
    @callback_runner = CallbackRunner.new
  end

  def test_constants_are_defined
    assert defined?(BillingClient)
    assert defined?(KeywordDelegationProxy)
    assert defined?(RetryProxy)
    assert defined?(CurrencyNormalizer)
    assert defined?(InstrumentedBillingClient)
    assert defined?(CallbackRunner)
  end

  def test_billing_client_charge_returns_expected_shape
    result = @client.charge('cust-1', amount: 12.5, currency: 'eur', metadata: { plan: 'pro' }, notify: true)

    assert_equal 'cust-1', result[:customer_id]
    assert_equal 12.5, result[:amount]
    assert_equal 'eur', result[:currency]
    assert_equal({ plan: 'pro' }, result[:metadata])
    assert_equal true, result[:notify]
  end

  def test_billing_client_requires_amount_keyword
    assert_raises(ArgumentError) do
      @client.charge('cust-1')
    end
  end

  def test_billing_client_rejects_unknown_keywords
    assert_raises(ArgumentError) do
      @client.charge('cust-1', amount: 10, unexpected: true)
    end
  end

  def test_billing_client_yields_payload_to_block
    result = @client.charge('cust-1', amount: 9.5) { |payload| payload[:amount] * 2 }
    assert_equal 19.0, result[:block_result]
  end

  def test_proxy_forwards_positional_and_keyword_arguments
    result = @proxy.charge('cust-2', amount: 3.25, currency: 'usd', notify: true)

    assert_equal 'cust-2', result[:customer_id]
    assert_equal 3.25, result[:amount]
    assert_equal 'usd', result[:currency]
    assert_equal true, result[:notify]
  end

  def test_proxy_forwards_blocks
    result = @proxy.charge('cust-2', amount: 10) { |payload| "#{payload[:customer_id]}:#{payload[:amount]}" }
    assert_equal 'cust-2:10.0', result[:block_result]
  end

  def test_proxy_respond_to_missing_mirrors_target
    assert @proxy.respond_to?(:charge)
    assert @proxy.respond_to?(:capability)
    refute @proxy.respond_to?(:not_a_method)
  end

  def test_proxy_preserves_keyword_error_behavior
    assert_raises(ArgumentError) do
      @proxy.charge('cust-3', amount: 10, unknown: 'x')
    end
  end

  def test_proxy_does_not_convert_hash_to_keywords
    assert_raises(ArgumentError) do
      @proxy.charge('cust-4', { amount: 5.0 })
    end
  end

  def test_proxy_records_call_metadata
    @proxy.charge('cust-5', amount: 7, currency: 'gbp', notify: false)
    call = @proxy.calls.last

    assert_equal :charge, call[:name]
    assert_equal ['cust-5'], call[:args]
    assert_equal %i[amount currency notify], call[:kwargs]
  end

  def test_nested_proxy_chain_preserves_keywords
    result = @nested_proxy.charge('cust-6', amount: 15.75, metadata: { source: 'api' })

    assert_equal 15.75, result[:amount]
    assert_equal({ source: 'api' }, result[:metadata])
  end

  def test_retry_proxy_consumes_retries_keyword
    result = @retry_proxy.charge('cust-7', amount: 20, retries: 2)

    assert_equal 1, result[:attempts]
    assert_equal 20.0, result[:amount]
  end

  def test_retry_proxy_retries_on_transient_failure
    flaky = build_flaky_client(1)
    retrying = RetryProxy.new(flaky)

    result = retrying.charge('cust-8', amount: 11, retries: 1)
    assert_equal 2, result[:attempts]
    assert_equal 2, flaky.attempts
  end

  def test_retry_proxy_raises_when_retries_exhausted
    flaky = build_flaky_client(2)
    retrying = RetryProxy.new(flaky)

    assert_raises(RuntimeError) do
      retrying.charge('cust-9', amount: 11, retries: 1)
    end
  end

  def test_retry_proxy_forwards_block
    result = @retry_proxy.charge('cust-10', amount: 2.5) { |payload| payload[:amount] + 1 }
    assert_equal 3.5, result[:block_result]
  end

  def test_prepend_normalizer_runs_before_base_method
    result = @instrumented_client.charge('cust-11', amount: 10, currency: 'eur')
    assert_equal 'EUR', result[:currency]
  end

  def test_prepend_changes_method_lookup_order
    assert_equal CurrencyNormalizer, InstrumentedBillingClient.ancestors.first
  end

  def test_include_module_still_present_in_ancestors
    assert_includes InstrumentedBillingClient.ancestors, Taggable
  end

  def test_class_method_overrides_included_module_method
    assert_equal 'class-tag', @instrumented_client.source_tag
  end

  def test_callback_runner_executes_lambda
    doubler = ->(value) { value * 2 }
    assert_equal 8, @callback_runner.run(doubler, 4)
  end

  def test_callback_runner_enforces_lambda_arity
    single = ->(value) { value }
    assert_raises(ArgumentError) { @callback_runner.run(single, 1, 2) }
  end

  def test_callback_runner_proc_has_lenient_arity
    collector = proc { |left, right| [left, right] }
    assert_equal [1, nil], @callback_runner.run(collector, 1)
  end

  def test_callback_runner_detects_lambda_vs_proc
    lambda_callback = ->(value) { value }
    proc_callback = proc { |value| value }

    assert_equal :lambda, @callback_runner.callback_type(lambda_callback)
    assert_equal :proc, @callback_runner.callback_type(proc_callback)
  end

  def test_callback_runner_handles_non_local_return_proc
    callback = build_non_local_return_proc
    assert_equal :local_jump_error, @callback_runner.guarded_run(callback, 1)
  end

  def test_lambda_return_is_safe
    callback = -> { :lambda_return }
    assert_equal :lambda_return, @callback_runner.run(callback)
  end

  private

  def build_non_local_return_proc
    proc { return :escaped }
  end

  def build_flaky_client(failures_before_success)
    klass = Class.new(BillingClient) do
      attr_reader :attempts

      define_method(:initialize) do |failure_count|
        super()
        @failures_left = failure_count
        @attempts = 0
      end

      define_method(:charge) do |customer_id, amount:, currency: 'USD', metadata: {}, notify: false, &block|
        @attempts += 1
        if @failures_left.positive?
          @failures_left -= 1
          raise 'temporary failure'
        end

        super(customer_id, amount: amount, currency: currency, metadata: metadata, notify: notify, &block)
      end
    end

    klass.new(failures_before_success)
  end
end
