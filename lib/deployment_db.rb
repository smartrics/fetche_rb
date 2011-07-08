require 'singleton'
require 'securerandom'

class DeploymentDb
  include Singleton
  def add new_data
    new_data["id"] = (new_data.object_id * 17 + SecureRandom.random_number(10000)).to_s
    data << new_data
  end

  
  
  def load db
    content = db
    File.open(db) do | f |
      content = f.read
    end if db.kind_of?(IO)
    p = JSON::Parser.new(content)
    @data = p.parse
  end

  def get ids
    ret_data = data.dup
    ret_data.delete_if do | d |
      common = [d["id"]] & ids
      common.size == 0
    end
    ret_data
  end

  def del id
    data.delete_if do | d |
      d["id"] == id
    end
  end

  def data
    @data
  end

end