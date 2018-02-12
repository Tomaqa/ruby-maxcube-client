
module MaxCube
  class MessageSerializer < MessageHandler
    private

    module MessageU
      KEYS = %i[url port].freeze
    end

    # Command to configure Cube's portal URL
    def serialize_u(hash)
      "#{hash[:url]}:#{to_int(0, 'port', hash[:port])}"
    end
  end
end