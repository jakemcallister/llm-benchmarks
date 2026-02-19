# frozen_string_literal: true

require 'benchmark'
require 'tempfile'
require 'minitest'

class KeywordDelegationProxyBenchmark
  def self.run(implementation_path)
    benchmark_start_time = Time.now

    require File.expand_path(implementation_path, File.dirname(__FILE__))
    fixed_code_class = KeywordDelegationProxy

    test_result = run_tests_on_fixed_code(fixed_code_class)

    execution_time = Time.now - benchmark_start_time

    {
      tests_passed: test_result[:passed],
      total_tests: test_result[:total],
      success: test_result[:passed].positive? && test_result[:syntax_valid],
      execution_time: execution_time.round(4),
      syntax_valid: test_result[:syntax_valid],
      error_message: test_result[:error_message]
    }
  rescue StandardError => e
    {
      tests_passed: 0,
      total_tests: total_test_count,
      success: false,
      execution_time: 0,
      syntax_valid: false,
      error_message: e.message
    }
  end

  def self.run_tests_on_fixed_code(_fixed_code_class)
    result = { passed: 0, total: 0, syntax_valid: true, error_message: nil }

    begin
      test_methods = KeywordDelegationProxyTest.instance_methods(true)
                                               .select { |m| m.to_s.start_with?('test_') }
                                               .sort
      result[:total] = test_methods.count

      test_methods.each do |test_method|
        test_instance = KeywordDelegationProxyTest.new(test_method.to_s)

        test_instance.setup
        test_instance.send(test_method)
        test_instance.teardown if test_instance.respond_to?(:teardown)

        result[:passed] += 1
      rescue Minitest::Assertion, StandardError
        test_instance.teardown if test_instance.respond_to?(:teardown)
      end
    rescue StandardError => e
      result[:syntax_valid] = false
      result[:error_message] = e.message
    end

    result
  end

  def self.total_test_count
    KeywordDelegationProxyTest.instance_methods(true).count { |m| m.to_s.start_with?('test_') }
  end
end

require_relative 'test_suite'
