%w(
  net/http
  json
).each &method(:require)

require 'terpene/client'

# The module containing the interface to Nacreon.  You are likely to be
# interested in Terpene::Client for interactions with Nacreon
# through Ruby, or Terpene::Command for interactions with Nacreon
# through the shell
module Terpene
  # The exception class from which all Terpene errors originate.
  class Error < ::StandardError; end
  # The client has attempted to access a resource, but is not authenticated.
  class AuthenticationError < Error; end
end
