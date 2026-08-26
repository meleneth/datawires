# frozen_string_literal: true

require "ipaddr"
require "resolv"

module Sources
  class NetworkPolicy
    BLOCKED_RANGES = [
      IPAddr.new("0.0.0.0/8"), IPAddr.new("10.0.0.0/8"), IPAddr.new("100.64.0.0/10"),
      IPAddr.new("127.0.0.0/8"), IPAddr.new("169.254.0.0/16"), IPAddr.new("172.16.0.0/12"),
      IPAddr.new("192.0.0.0/24"), IPAddr.new("192.0.2.0/24"), IPAddr.new("192.168.0.0/16"),
      IPAddr.new("198.18.0.0/15"), IPAddr.new("198.51.100.0/24"), IPAddr.new("203.0.113.0/24"),
      IPAddr.new("224.0.0.0/4"), IPAddr.new("240.0.0.0/4"), IPAddr.new("::/128"),
      IPAddr.new("::1/128"), IPAddr.new("2001:db8::/32"), IPAddr.new("fc00::/7"),
      IPAddr.new("fe80::/10"), IPAddr.new("ff00::/8")
    ].freeze

    def self.validate!(uri)
      return true if allowed_hosts.include?(uri.host)

      addresses = Resolv.getaddresses(uri.host)
      raise UnsafeAddress, "source host did not resolve" if addresses.empty?
      raise UnsafeAddress, "source host resolves to a private or reserved address" if addresses.any? { |value| blocked?(value) }

      true
    end

    def self.allowed_hosts
      ENV.fetch("DATAWIRES_SOURCE_ALLOWED_HOSTS", "").split(",").map(&:strip).reject(&:blank?)
    end

    def self.blocked?(value)
      address = IPAddr.new(value)
      BLOCKED_RANGES.any? { |range| range.include?(address) }
    rescue IPAddr::InvalidAddressError
      true
    end

    class UnsafeAddress < StandardError; end
  end
end
