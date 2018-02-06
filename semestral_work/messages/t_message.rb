
module MaxCube
  class MessageSerializer < MessageHandler
    private

    module MessageT
    end

    # Command to delete one or more devices from the Cube
    # Acknowledgement (A) follows
    def serialize_t(hash)
      count = format('%02x', hash[:count])
      force = hash[:force] ? '1' : '0'
      addrs = encode(hash[:rf_addresses].join)
      [count, force, addrs].join(',')
    end
  end
end