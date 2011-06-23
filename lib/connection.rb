require 'net/ssh'

class Connection
  def initialize args_map
    @user = args_map[:user]
    @host = args_map[:host]
  end

  def execute command, progress_listener
    Net::SSH.start(@host, @user, :forward_agent => true, :verbose => :debug, :log => progress_listener) do |session|
      session.execute command
    end
  end
end