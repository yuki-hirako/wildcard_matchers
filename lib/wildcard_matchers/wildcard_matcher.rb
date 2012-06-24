module WildcardMatchers
  class WildcardMatcher
    attr_reader :expectation, :errors
    attr_accessor :position

    def initialize(expectation = nil, position = ".", &block)
      @expectation = (block_given? ? block : expectation)
      @position    = position
    end

    def ===(actual)
      @errors = []
      wildcard_match(actual)
      errors.empty?
    end

    def self.check_errors(actual, expectation = nil, position = ".", &block)
      expectation = (block_given? ? block : expectation)
      matcher = self.new(expectation, position)
      matcher === actual
      matcher.errors
    end

    protected
    def wildcard_match(actual)
      case expectation
      when self.class
        expectation.position = position
        expectation === actual
        errors.push(*expectation.errors)
      when Class
        # fo Array or Hash Class
        single_match(actual)
      when Proc
        # TODO: use sexp
        single_match(actual)
      when Array
        errors.push(*ArrayMatcher.check_errors(actual, expectation, position))
      when Hash
        errors.push(*HashMatcher.check_errors(actual, expectation, position))
      else
        single_match(actual)
      end
    end

    def single_match(actual)
      unless expectation === actual
        errors << "#{position}: expect #{actual.inspect} to #{expectation.inspect}"
      end
    end
  end

  class ArrayMatcher < WildcardMatcher
    protected
    def wildcard_match(actual)
      unless actual.is_a?(Array)
        errors << "#{position}: expect #{actual.inspect} to #{expectation.inspect}"
        return
      end

      if expectation.size === actual.size
        expectation.zip(actual).each.with_index do |(e, a), i|
          errors.push(*self.class.superclass.check_errors(a, e, position + "[#{i}]"))
        end
      else
        errors << "#{position}: expect Array size #{actual.size} to #{expectation.size}"
        # TODO: diff-lcs
      end
    end
  end

  class HashMatcher < WildcardMatcher
    protected
    def wildcard_match(actual)
      unless actual.is_a?(Hash)
        errors << "#{position}: expect #{actual.inspect} to #{expectation.inspect}"
        return
      end

      if (actual.keys - expectation.keys).size == 0 && (expectation.keys - actual.keys).size == 0
        expectation.each do |key, value|
          errors.push(*self.class.superclass.check_errors(actual[key], value, position + "[#{key.inspect}]"))
        end
      else
        errors << "#{position}: expect Hash keys #{actual.keys} to #{expectation.keys}"
        #TODO: diff-lcs
      end
    end
  end
end