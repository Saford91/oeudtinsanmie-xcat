require File.expand_path(File.join(File.dirname(__FILE__), '.', 'xcatprovider'))
class Puppet::Provider::Xcatobject < Puppet::Provider::Xcatprovider

  # Without initvars commands won't work.
  initvars
  commands  :lsdef => '/opt/xcat/bin/lsdef',
            :mkdef => '/opt/xcat/bin/mkdef',
            :rmdef => '/opt/xcat/bin/rmdef',
            :chdef => '/opt/xcat/bin/chdef'

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    list_obj.collect { |obj|
      new(make_hash(obj))
    }
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def self.list_obj
    cmd_list = ["-l", "-t", xcat_type]
    begin
      output = lsdef(cmd_list)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::DevError, "lsdef #{cmd_list.join(' ')} had an error -> #{e.inspect}"
    end

    obj_strs = output.split("Object name: ")
    obj_strs.delete("")
    obj_strs
  end

  def self.make_hash(obj_str)
    hash_list = obj_str.split("\n")
    inst_name = hash_list.shift
    inst_hash = Hash.new
    inst_hash[:name]   = inst_name
    inst_hash[:ensure] = :present
    hash_list.each { |line|
      key, delim, value = line.partition("=")

      if (value.include? ",") then
        inst_hash[key.lstrip] = value.split(",")
      else
        inst_hash[key.lstrip] = value
      end
    }
    Puppet::Util::symbolizehash(inst_hash)
  end

  def flush
    cmd_list = ["-t", self.class.xcat_type, "-o", resource[:name]]
    if (@property_flush[:ensure] == :absent) then
      # rmdef
      begin
        rmdef(cmd_list)
        @property_flush = nil
      rescue Puppet::ExecutionFailure => e
        raise Puppet::DevError, "rmdef #{cmd_list.join(' ')} failed to run: #{e}"
      end
    else
      resource.to_hash.each { |key, value|
        if not self.class.puppetkeywords.include?(key)
          if (value.is_a?(Array)) then
            cmd_list += ["#{key}=#{value.join(',')}"]
            Puppet.debug "Setting #{key} = #{value.join(',')}"
          else
            Puppet.debug "Setting #{key} = #{value}"
            cmd_list += ["#{key}=#{value}"]
          end
        end
      }
      if (@property_flush[:ensure] == :present) then
        # mkdef
        begin
          mkdef(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::DevError, "mkdef #{cmd_list.join(' ')} failed to run: #{e}"
        end
      else
        # chdef
        begin
          chdef(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::DevError, "chdef #{cmd_list.join(' ')} failed to run: #{e}"
        end
      end
    end
  end
end
