# frozen_string_literal: true

module Observations
  module AggregateProviders
    class Count
      def self.call(values) = values.length.to_f
    end

    class Sum
      def self.call(values) = values.sum
    end

    class Min
      def self.call(values) = values.min
    end

    class Max
      def self.call(values) = values.max
    end

    class Last
      def self.call(values) = values.last
    end

    class Average
      def self.call(values) = values.sum / values.length
    end
  end
end
