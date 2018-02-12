
module MaxCube
  class Client
    private

    def list_hashes(history)
      buffer(:recv, :hashes, history).each_with_index do |h, i|
        puts "<#{i + 1}>"
        print_hash(h)
        puts
      end
    end

    def cmd_data
      list_hashes(false)
    end

    def cmd_history
      list_hashes(true)
    end

    def cmd_clear
      %i[data hashes].each do |sym|
        @history[:recv][sym] += @buffer[:recv][sym]
        @buffer[:recv][sym].clear
      end
    end

    def cmd_dump
      cmd_data
      cmd_clear
    end

    def cmd_list
      send_msg('l')
    end

    def cmd_config
      send_msg('c')
    end

    def cmd_pair(*args)
      send_msg('n', *args)
    end

    def cmd_url(*args)
      send_msg('u', *args)
    end

    def cmd_ntp(*args)
      send_msg('f', *args, array: true)
    end

    def cmd_wake(*args)
      send_msg('z', *args)
    end

    def cmd_metadata(*args)
      send_msg('m', *args, load_only: true)
    end

    def cmd_delete(*args)
      send_msg('t', *args, array: true, array_nonempty: true)
    end

    def cmd_reset
      send_msg('a')
    end

    def toggle(name, flag)
      puts "#{name}: #{flag} -> #{!flag}"
      !flag
    end

    def cmd_verbose
      @verbose = toggle('verbose', @verbose)
    end

    SAVE_DIR = './data/'.freeze

    def cmd_save(what = nil)
      buffer = !what
      all = %w[a A all].include?(what)
      unless all || buffer
        puts "Unrecognized argument: '#{what}'"
        return
      end

      %i[recv sent].each do |sym|
        data_fn = SAVE_DIR + sym.to_s + '.data'
        File.open(data_fn, 'w') do |f|
          f.puts(buffer(sym, :data, all).join)
        end

        hashes_fn = SAVE_DIR + sym.to_s + '.yaml'
        File.open(hashes_fn, 'w') do |f|
          buffer(sym, :hashes, all).to_yaml(f)
        end
      end

      puts "Received and sent raw data and hashes saved into '#{SAVE_DIR}'"
    end

    def parse_hash(path)
      unless File.file?(path) && File.readable?(path)
        return puts "File is not readable: '#{path}'"
      end

      hash = YAML.load_file(path)
      hash = hash.first while hash.is_a?(Array)
      raise YAML::SyntaxError unless hash.is_a?(Hash)
      hash
    rescue YAML::SyntaxError
      puts "File '#{path}' does not contain a YAML hash"
    end

    def load_hash(path = nil)
      return parse_hash(path) if path
      return @hash if @hash && @hash_set

      if @hash
        puts 'Internal hash is not set'
      else
        puts 'No internal hash loaded yet'
        cmd_usage
      end
    end

    def assign_hash(hash)
      valid_hash = !hash.nil?
      @hash = hash if valid_hash
      @hash_set |= valid_hash
      valid_hash
    end

    def cmd_load(path = nil)
      hash = load_hash(path)
      print_hash(hash) if assign_hash(hash)
    end

    def cmd_persist
      @persist = toggle('persist', @persist)
      @hash_set = @persist if @hash
    end

    def cmd_quit
      raise Interrupt
    end

    def usage_line(command, args, description, message = nil, response = nil)
      cmds_str = (COMMANDS[command].dup << command).join('|')
      cmds_str << ' ' << args unless args.empty?

      description, *rest = description.split("\n")
      rest << "[#{message} message]" if message
      rest << "[#{response} response]" if response
      rest = if rest.empty?
               ''
             else
               rest.map { |s| ' ' * 52 + s }.join("\n") << "\n"
             end

      '  ' << cmds_str << ' ' * (48 - cmds_str.size) <<
        description << "\n" << rest
    end

    def cmd_usage
      puts "\nUSAGE: <command> [<arguments...>]\nCOMMADS:\n" <<
           usage_line('usage', '',
                      'Prints this message') <<
           usage_line('data', '',
                      'Lists buffered received data (hashes)') <<
           usage_line('history', '',
                      'Lists all received data incl. the cleared') <<
           usage_line('clear', '',
                      "Clears collected data\n(resp. moves it to history)") <<
           usage_line('dump', '',
                      "Shortcut for 'data' + 'clear'") <<
           usage_line('list', '',
                      'Requests for new list of devices', 'l', 'L') <<
           usage_line('config', '',
                      'Requests for configuration message', 'c', 'C') <<
           usage_line('pair', '{<timeout>}',
                      "Sets device into pairing mode with optional timeout\n" \
                      '(request for a new device)', 'n', 'N') <<
           usage_line('url', '{<URL> <port>}',
                      'Configures Cube\'s portal URL', 'u') <<
           usage_line('ntp', '{<NTP servers...>}',
                      'Requests for NTP servers and optionally updates them',
                      'f', 'F') <<
           usage_line('wake', '{<time> <scope> [<ID>]}',
                      'Wake-ups the Cube',
                      'z', 'A') <<
           usage_line('metadata', '{}',
                      'Serializes metadata for the Cube',
                      'm', 'M') <<
           usage_line('send', '{}',
                      'Sends settings to connected devices',
                      's', 'S') <<
           usage_line('delete', '{<count> <force> <RF addresses...>}',
                      'Deletes one or more devices from the Cube (!)',
                      't', 'A') <<
           usage_line('reset', '',
                      'Requests for factory reset (!)', 'a', 'A') <<
           usage_line('verbose', '',
                      "Toggles verbose mode (whether is incoming data\n" \
                      'printed immediately or is not printed)') <<
           usage_line('save', '[a|A|all]',
                      "Saves buffered [all] received and sent data\n" \
                      'into files') <<
           usage_line('load', '[<path>]',
                      "Loads first hash from YAML file to internal variable\n" \
                      "-> to pass data with sent message\n" \
                      "(loads previous valid hash if no file given)\n" \
                      "(command can be combined using '#{ARGS_FROM_HASH}'\n" \
                      " with other commands which have '{}' arguments)") <<
           usage_line('persist', '',
                      "Toggles persistent mode (whether is internal hash\n" \
                      'not invalidated after use)') <<
           usage_line('quit', '',
                      "Shuts the client down gracefully\n" \
                      '(SIGINT and EOF also work)', 'q') <<
           "\n[<arg>] means optional argument <arg>" \
           "\n[<args...>] means multiple arguments <args...> or none" \
           "\n  (<args...> requires at least one)" \
           "\n{<arg>} means that either <arg>" \
           " or '#{ARGS_FROM_HASH}' is expected" \
           "\n  (when '#{ARGS_FROM_HASH}' specified as first argument," \
           ' internal hash is used' \
           "\n   -> 'load' command is called with rest arguments)" \
           "\n  ({} means that only internal hash can be used," \
           "\n   '#{ARGS_FROM_HASH}' is not necessary in this case)"
    end
  end
end