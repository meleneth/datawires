# frozen_string_literal: true

module Metrics
  module DerivedOperations
    class Add
      def self.call(left, right) = left + right
    end

    class Subtract
      def self.call(left, right) = left - right
    end

    class Multiply
      def self.call(left, right) = left * right
    end

    class Divide
      def self.call(left, right)
        raise ZeroDivisionError, "derived metric divisor is zero" if right.zero?

        left / right
      end
    end
  end
end
