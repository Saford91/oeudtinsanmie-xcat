require File.expand_path(File.join(File.dirname(__FILE__), '..', 'xcatobject'))
Puppet::Type.type(:xcat_network).provide(:xcat, :parent => Puppet::Provider::Xcatobject) do

  mk_resource_methods

  def self.xcat_type
    "network"
  end

end
