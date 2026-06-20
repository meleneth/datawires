# frozen_string_literal: true

require "erb"

# Rails 7's ActionView references ERB::ENCODING_FLAG. Ruby 4 ships ERB as a
# default gem where that constant is no longer defined, so provide the small
# pattern Rails expects before ActionView loads.
unless ::ERB.const_defined?(:ENCODING_FLAG)
  ::ERB.const_set(:ENCODING_FLAG, '#.*coding[:=]\s*([A-Za-z0-9_-]+)')
end

::Object.const_set(:ENCODING_FLAG, ::ERB::ENCODING_FLAG) unless ::Object.const_defined?(:ENCODING_FLAG)
