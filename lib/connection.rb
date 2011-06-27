require 'net/ssh'

class Connection
  attr_reader :user, :host, :verbose, :key
  def initialize args_map
    @user = args_map[:user]
    raise "user is mandatory" if @user.nil?
    @host = args_map[:host]
    raise "host is mandatory" if @host.nil?
    @key = args_map[:key] || ENV['PRIVATE_KEY']
    @password = args_map[:password]
    raise "key or password are mandatory" if @key.nil? && @password.nil?
    @verbose = :warning
    @verbose = :debug if args_map[:verbose] == true
  end

  def password_given?
    !@password.nil?
  end
  
  def execute command, progress_listener
    io_listener = progress_listener if progress_listener.kind_of(IO)
    buffer = ""
    Net::SSH.start(@host, @user,
        :paranoid => false,
        :verbose => @verbose,
        :log => progress_listener,
        :key => @key,
        :password => @password) do |session|
      session.open_channel do | channel |
        channel.on_data do | ch, data |
          if block_given?
            yield data
          end
          buffer << data
        end
        channel.exec command
      end
    end
    buffer
  end
end