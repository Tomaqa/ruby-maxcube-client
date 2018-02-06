
module MaxCube
  class MessageParser < MessageHandler
    private

    module MessageN
    end

    # New device (pairing) message
    def parse_n(body)
      @io = StringIO.new(decode(body), 'rb')

      {
        device_type: device_type(read(1, 'C')),
        rf_address: read(3),
        serial_number: read(10),
        unknown: read(1),
      }
    rescue IOError
      raise InvalidMessageBody
        .new(@msg_type, 'unexpected EOF reached')
    end
  end

  class MessageSerializer < MessageHandler
    private

    module MessageN
    end

    # Command to set the Cube into pairing mode
    # with optional +timeout+ in seconds
    def serialize_n(hash)
      hash.include?(:timeout) ? format('%04x', hash[:timeout]) : ''
    end
  end
end