# frozen_string_literal: true

# Module for IBM HMC Rest API Client
module IbmPowerHmc
  # HMC generic object
  class HmcObject
    attr_reader :uuid

    def initialize(doc)
      @uuid = doc.elements["id"].text
    end

    def get_value(doc, xpath, varname)
      value = doc.elements[xpath].text.strip
      self.class.__send__(:attr_reader, "#{varname}")
      instance_variable_set("@#{varname}", value)
    end

    def get_values(doc, hash)
      hash.each do |key, value|
        get_value(doc, key, value)
      end
    end

    def to_s
      "uuid=#{@uuid}"
    end
  end

  # HMC information
  class ManagementConsole < HmcObject
    XMLMAP = {
      "ManagementConsoleName" => "name",
      "VersionInfo/BuildLevel" => "build_level",
      "BaseVersion" => "version"
    }.freeze

    def initialize(doc)
      super(doc)
      info = doc.elements["content/ManagementConsole:ManagementConsole"]
      get_values(info, XMLMAP)
    end

    def to_s
      "hmc name=#{@name} version=#{@version} build_level=#{@build_level}"
    end
  end

  # Managed System information
  class ManagedSystem < HmcObject
    XMLMAP = {
      "SystemName" => "name",
      "State" => "state",
      "Hostname" => "hostname",
      "PrimaryIPAddress" => "ipaddr",
      "AssociatedSystemMemoryConfiguration/InstalledSystemMemory" => "memory",
      "AssociatedSystemMemoryConfiguration/CurrentAvailableSystemMemory" => "avail_mem",
      "AssociatedSystemProcessorConfiguration/InstalledSystemProcessorUnits" => "cpus",
      "AssociatedSystemProcessorConfiguration/CurrentAvailableSystemProcessorUnits" => "avail_cpus"
    }.freeze

    def initialize(doc)
      super(doc)
      info = doc.elements["content/ManagedSystem:ManagedSystem"]
      get_values(info, XMLMAP)
    end

    def to_s
      "sys name=#{@name} state=#{@state} ip=#{@ipaddr} mem=#{@memory}MB avail=#{@avail_mem}MB CPUs=#{@cpus} avail=#{@avail_cpus}"
    end
  end

  # Logical Partition information
  class LogicalPartition < HmcObject
    attr_reader :sys_uuid

    XMLMAP = {
      "PartitionName" => "name",
      "PartitionID" => "id",
      "PartitionState" => "state",
      "PartitionType" => "type",
      "PartitionMemoryConfiguration/CurrentMemory" => "memory",
      "PartitionProcessorConfiguration/HasDedicatedProcessors" => "dedicated"
    }.freeze

    def initialize(sys_uuid, doc)
      super(doc)
      @sys_uuid = sys_uuid
      info = doc.elements["content/LogicalPartition:LogicalPartition"]
      get_values(info, XMLMAP)
    end

    def to_s
      "lpar name=#{@name} id=#{@id} state=#{@state} type=#{@type} memory=#{@memory}MB dedicated cpus=#{@dedicated}"
    end
  end

  # VIOS information
  class VirtualIOServer < HmcObject
    attr_reader :sys_uuid

    XMLMAP = {
      "PartitionName" => "name",
      "PartitionID" => "id",
      "PartitionState" => "state",
      "PartitionType" => "type",
      "PartitionMemoryConfiguration/CurrentMemory" => "memory",
      "PartitionProcessorConfiguration/HasDedicatedProcessors" => "dedicated"
    }.freeze

    def initialize(sys_uuid, doc)
      super(doc)
      @sys_uuid = sys_uuid
      info = doc.elements["content/VirtualIOServer:VirtualIOServer"]
      get_values(info, XMLMAP)
    end

    def to_s
      "vios name=#{@name} id=#{@id} state=#{@state} type=#{@type} memory=#{@memory}MB dedicated cpus=#{@dedicated}"
    end
  end

  # LPAR profile
  class LogicalPartitionProfile < HmcObject
    attr_reader :lpar_uuid

    # Damien: TBD
  end
end