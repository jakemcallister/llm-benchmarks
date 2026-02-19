# frozen_string_literal: true

class BillingClient
  def charge(customer_id, amount:, currency: 'USD', metadata: {}, notify: false, &block)
    raise ArgumentError, 'customer_id is required' if customer_id.nil?
    raise ArgumentError, 'amount must be numeric' unless amount.is_a?(Numeric)

    payload = {
      customer_id: customer_id.to_s,
      amount: amount.to_f.round(2),
      currency: currency.to_s,
      metadata: metadata.is_a?(Hash) ? metadata : {},
      notify: notify ? true : false
    }

    payload[:block_result] = yield(payload) if block
    payload
  end

  def capability
    :billing
  end
end

class KeywordDelegationProxy
  attr_reader :target, :calls

  def initialize(target)
    @target = target
    @calls = []
  end

  def method_missing(name, *args, **kwargs, &)
    @calls << {
      name: name,
      args: args,
      kwargs: kwargs.keys.sort
    }

    @target.public_send(name, *args, **kwargs, &)
  end

  def respond_to_missing?(name, include_private = false)
    @target.respond_to?(name, include_private) || super
  end
end

class RetryProxy < KeywordDelegationProxy
  def charge(*, retries: 0, **, &)
    max_retries = retries.to_i
    max_retries = 0 if max_retries.negative?

    attempts = 0
    begin
      attempts += 1
      result = target.charge(*, **, &)
      result.merge(attempts: attempts)
    rescue StandardError
      retry if attempts <= max_retries
      raise
    end
  end
end

module Taggable
  def source_tag
    'module-tag'
  end
end

module CurrencyNormalizer
  def charge(customer_id, amount:, currency: 'USD', metadata: {}, notify: false, &)
    super(
      customer_id,
      amount: amount,
      currency: currency.to_s.upcase,
      metadata: metadata,
      notify: notify,
      &
    )
  end
end

class InstrumentedBillingClient < BillingClient
  prepend CurrencyNormalizer
  include Taggable

  def source_tag
    'class-tag'
  end
end

class CallbackRunner
  def run(callback, *)
    callback.call(*)
  end

  def guarded_run(callback, *)
    run(callback, *)
  rescue LocalJumpError
    :local_jump_error
  end

  def callback_type(callback)
    callback.lambda? ? :lambda : :proc
  end
end
