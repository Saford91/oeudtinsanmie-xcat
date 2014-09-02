require File.expand_path(File.join(File.dirname(__FILE__), '..', 'xcatobject'))
Puppet::Type.type(:xcat_node).provide(:xcat, :parent => Puppet::Provider::Xcatobject) do

  mk_resource_methods
  
  @xcat_type = "node"
  
  def initialize(value={})
    super(value)
    @property_flush = {}
  end
            
  def self.instances
    super.list_obj(@xcat_type).collect { |obj|
      new(obj)
    }
  end
  
  def self.prefetch(resources)
    self.instances.each do |prov|
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
  
  def flush
    begin
      super.doflush(@xcat_type)
      
      @property_flush = nil
      # refresh @property_hash
      @property_hash = super.make_hash(list_obj(@xcat_type, resource[:name])[0])
    rescue Exception => e
      @property_hash.clear
      raise Puppet::Error, e
    end
  end
end

