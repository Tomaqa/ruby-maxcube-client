
module MaxCube
  # class MessageSerializer < MessageHandler
  class Messages
    module Serializer
      module TCP
    private

    module MessageT
      # +count+ argument would cause ambuigity if it was optional
      #   due to +rf_addresses+ has variable size
      KEYS = %i[count force rf_addresses].freeze
    end

    # Command to delete one or more devices from the Cube
    # Acknowledgement (A) follows
    def serialize_t(hash)
      force = to_bool('force mode', hash[:force]) ? '1' : '0'
      rf_addresses = to_ints(0, 'RF addresses', *hash[:rf_addresses])
      count = to_int(0, 'count', hash[:count])

      unless count == rf_addresses.size
        raise InvalidMessageBody
          .new(@msg_type,
               'count and number of devices mismatch: ' \
               "#{count} != #{rf_addresses.size}")
      end
      if count.zero?
        raise InvalidMessageBody
          .new(@msg_type, 'no device specified')
      end

      addrs = encode(serialize(*rf_addresses, esize: 3))
      [format('%02x', count), force, addrs].join(',')
    end
  end
end
end
end
