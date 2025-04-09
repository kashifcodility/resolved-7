#
# The purpose of this module is provide a standardized way to surface user
# facing messages through Ruby's exception raising mechanism.
#
# Example:
# raise Error.new(card.error.inspect, user_message: "Credit card processing error occurred.")
#
# Extending in a class:
# require 'sdn/exceptions'
# class Foo
#     module Exceptions < ::SDN::Exceptions
#         class BarError < Error; end
#     end
# end
# 
# TODO: Think through and add logging mechanisms here (DRY)
module SDN::Exceptions
    
    class Error < RuntimeError
        const_def :DEFAULT_USER_MESSAGE, "Unknown error."
        
        attr_reader :user_message

        # Adds user facing message support
        #
        # Examples:
        # Error.new("technical error message", user_message: "user facing error message")
        # Error.new("technical error message", user_message: :message) # technical error message == user error message
        def initialize(message, user_message:nil)
            super(message)
            @user_message = user_message == :message ? message : user_message || self::DEFAULT_USER_MESSAGE
        end
    end

end
    
