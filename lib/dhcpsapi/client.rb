module DhcpsApi
  module Client
    # Returns a a list of subnet clients (Windows 2008-compatible version).
    #
    # @example List subnet clients
    #
    # api.list_clients_2008('192.168.42.0')
    #
    # @param subnet_address [String] Subnet ip address
    #
    # @return [Array<Hash>]
    #
    # @see DHCP_CLIENT_INFO_V4 DHCP_CLIENT_INFO_V4 documentation for the list of available fields.
    #
    def list_clients_2008(subnet_address)
      items, _ = retrieve_items(:dhcp_enum_subnet_clients_v4, subnet_address, 1024, 0)
      items
    end

    # Returns a a list of subnet clients (Windows 2012-compatible version).
    #
    # @example List subnet clients
    #
    # api.list_clients('192.168.42.0')
    #
    # @param subnet_address [String] Subnet ip address
    #
    # @return [Array<Hash>]
    #
    # @see DHCP_CLIENT_INFO_PB DHCP_CLIENT_INFO_PB documentation for the list of available fields.
    #
    def list_clients(subnet_address)
      items, _ = retrieve_items(:dhcp_v4_enum_subnet_clients, subnet_address, 1024, 0)
      items
    end

    # TODO: parse lease time and owner_host
    # creates a new subnet client.
    #
    # @example create a new client
    #
    # api.create_client('192.168.42.42', '255.255.255.0', '00:01:02:03:04:05', 'test-client', 'test client comment', 0)
    #
    # @param client_ip_address [String] Client ip address
    # @param client_subnet_mask [String] Client subnet mask
    # @param client_mac_address [String] Client hardware address
    # @param client_name [String] Client name
    # @param client_comment [String] Client comment
    # @param lease_expires [Date] Client lease expiration date and time
    # @param client_type [ClientType] Client type
    #
    # @return [Hash]
    #
    # @see DHCP_CLIENT_INFO_V4 DHCP_CLIENT_INFO_V4 documentation for the list of available fields.
    # @see ClientType ClientType documentation for the list of available client types.
    #
    def create_client(client_ip_address, client_subnet_mask, client_mac_address,
                      client_name, client_comment, lease_expires, client_type = DhcpsApi::ClientType::CLIENT_TYPE_BOTH)
      to_create = DhcpsApi::DHCP_CLIENT_INFO_V4.new
      to_create[:client_ip_address] = ip_to_uint32(client_ip_address)
      to_create[:subnet_mask] = ip_to_uint32(client_subnet_mask)
      to_create[:client_hardware_address].intialize_with_mac_address(client_mac_address)

      to_create[:client_name] = FFI::MemoryPointer.from_string(to_wchar_string(client_name))
      to_create[:client_comment] = FFI::MemoryPointer.from_string(to_wchar_string(client_comment))

      to_create[:client_lease_expires][:dw_low_date_time] = 0
      to_create[:client_lease_expires][:dw_high_date_time] = 0
      to_create[:client_type] = client_type

      error = DhcpsApi::Win2008::Client.DhcpCreateClientInfoV4(to_wchar_string(server_ip_address), to_create.pointer)
      raise DhcpsApi::Error.new("Error creating client.", error) if error != 0

      to_create.as_ruby_struct
    end

    # TODO: parse lease time and owner_host
    # Modifies an existing subnet client.
    #
    # @example modify a client
    #
    # api.modify_client('192.168.42.42', '255.255.255.0', '00:01:02:03:04:05', 'test-client', 'test client comment', 0)
    #
    # @param client_ip_address [String] Client ip address
    # @param client_subnet_mask [String] Client subnet mask
    # @param client_mac_address [String] Client hardware address
    # @param client_name [String] Client name
    # @param client_comment [String] Client comment
    # @param lease_expires [Date] Client lease expiration date and time
    # @param client_type [ClientType] Client type
    #
    # @return [Hash]
    #
    # @see DHCP_CLIENT_INFO_V4 DHCP_CLIENT_INFO_V4 documentation for the list of available fields.
    # @see ClientType ClientType documentation for the list of available client types.
    #
    def modify_client(client_ip_address, client_subnet_mask, client_mac_address,
                      client_name, client_comment, lease_expires, client_type = DhcpsApi::ClientType::CLIENT_TYPE_BOTH)
      to_modify = DhcpsApi::DHCP_CLIENT_INFO_V4.new
      to_modify[:client_ip_address] = ip_to_uint32(client_ip_address)
      to_modify[:subnet_mask] = ip_to_uint32(client_subnet_mask)
      to_modify[:client_hardware_address].intialize_with_mac_address(client_mac_address)

      to_modify[:client_name] = FFI::MemoryPointer.from_string(to_wchar_string(client_name))
      to_modify[:client_comment] = FFI::MemoryPointer.from_string(to_wchar_string(client_comment))

      to_modify[:client_lease_expires][:dw_low_date_time] = 0
      to_modify[:client_lease_expires][:dw_high_date_time] = 0
      to_modify[:client_type] = client_type

      error = DhcpsApi::Win2008::Client.DhcpSetClientInfoV4(to_wchar_string(server_ip_address), to_modify.pointer)
      raise DhcpsApi::Error.new("Error modifying client.", error) if error != 0

      to_modify.as_ruby_struct
    end

    def get_client_subnet(client)
      uint32_to_ip(ip_to_uint32(client[:client_ip_address]) & ip_to_uint32(client[:subnet_mask]))
    end

    # Retrieves subnet client using client mac address.
    #
    # @example retrieve a client
    #
    # api.get_client_by_mac_address('192.168.42.0', '00:01:02:03:04:05')
    #
    # @param subnet_address [String] Subnet address
    # @param client_mac_address [String] Client hardware address
    #
    # @return [Hash]
    #
    # @see DHCP_CLIENT_INFO_V4 DHCP_CLIENT_INFO_V4 documentation for the list of available fields.
    #
    def get_client_by_mac_address(subnet_address, client_mac_address)
      search_info = DhcpsApi::DHCP_SEARCH_INFO.new
      search_info[:search_type] = DhcpsApi::DHCP_SEARCH_INFO_TYPE::DhcpClientHardwareAddress
      search_info[:search_info][:client_hardware_address].initialize_with_subnet_and_mac_addresses(subnet_address, client_mac_address)

      get_client(search_info, client_mac_address)
    end

    # Retrieves subnet client using client ip address.
    #
    # @example retrieve a client
    #
    # api.get_client_by_ip_address('192.168.42.42')
    #
    # @param client_ip_address [String] Client ip address
    #
    # @return [Hash]
    #
    # @see DHCP_CLIENT_INFO_V4 DHCP_CLIENT_INFO_V4 documentation for the list of available fields.
    #
    def get_client_by_ip_address(client_ip_address)
      search_info = DhcpsApi::DHCP_SEARCH_INFO.new
      search_info[:search_type] = DhcpsApi::DHCP_SEARCH_INFO_TYPE::DhcpClientIpAddress
      search_info[:search_info][:client_ip_address] = ip_to_uint32(client_ip_address)

      get_client(search_info, client_ip_address)
    end

    # Retrieves subnet client using client name.
    #
    # @example retrieve a client
    #
    # api.get_client_by_name('test-client')
    #
    # @param client_name [String] Client name
    #
    # @return [Hash]
    #
    # @see DHCP_CLIENT_INFO_V4 DHCP_CLIENT_INFO_V4 documentation for the list of available fields.
    #
    def get_client_by_name(client_name)
      search_info = DhcpsApi::DHCP_SEARCH_INFO.new
      search_info[:search_type] = DhcpsApi::DHCP_SEARCH_INFO_TYPE::DhcpClientName
      search_info[:search_info][:client_name] = FFI::MemoryPointer.from_string(to_wchar_string(client_name))

      get_client(search_info, client_name)
    end

    # Deletes subnet client using client mac address.
    #
    # @example delete a client
    #
    # api.delete_client_by_mac_address('192.168.42.0', '00:01:02:03:04:05')
    #
    # @param subnet_address [String] Subnet address
    # @param client_mac_address [String] Client hardware address
    #
    # @return [void]
    #
    def delete_client_by_mac_address(subnet_address, client_mac_address)
      search_info = DhcpsApi::DHCP_SEARCH_INFO.new
      search_info[:search_type] = DhcpsApi::DHCP_SEARCH_INFO_TYPE::DhcpClientHardwareAddress
      search_info[:search_info][:client_hardware_address].initialize_with_subnet_and_mac_addresses(subnet_address, client_mac_address)

      error = DhcpsApi::Win2008::Client.DhcpDeleteClientInfo(to_wchar_string(server_ip_address), search_info.pointer)
      raise DhcpsApi::Error.new("Error deleting client.", error) if error != 0
    end

    # Deletes subnet client using client ip address.
    #
    # @example delete a client
    #
    # api.delete_client_by_ip_address('192.168.42.42')
    #
    # @param client_ip_address [String] Client ip address
    #
    # @return [void]
    #
    def delete_client_by_ip_address(client_ip_address)
      search_info = DhcpsApi::DHCP_SEARCH_INFO.new
      search_info[:search_type] = DhcpsApi::DHCP_SEARCH_INFO_TYPE::DhcpClientIpAddress
      search_info[:search_info][:client_ip_address] = ip_to_uint32(client_ip_address)

      error = DhcpsApi::Win2008::Client.DhcpDeleteClientInfo(to_wchar_string(server_ip_address), search_info.pointer)
      raise DhcpsApi::Error.new("Error deleting client.", error) if error != 0
    end

    # Deletes subnet client using client name.
    #
    # @example delete a client
    #
    # api.delete_client_by_name('test-client')
    #
    # @param client_name [String] Client name
    #
    # @return [void]
    #
    def delete_client_by_name(client_name)
      search_info = DhcpsApi::DHCP_SEARCH_INFO.new
      search_info[:search_type] = DhcpsApi::DHCP_SEARCH_INFO_TYPE::DhcpClientName
      search_info[:search_info][:client_name] = FFI::MemoryPointer.from_string(to_wchar_string(client_name))

      error = DhcpsApi::Win2008::Client.DhcpDeleteClientInfo(to_wchar_string(server_ip_address), search_info.pointer)
      raise DhcpsApi::Error.new("Error deleting client.", error) if error != 0
    end

    private
    def get_client(search_info, client_id)
      client_info_ptr_ptr = FFI::MemoryPointer.new(:pointer)

      error = DhcpsApi::Win2008::Client.DhcpGetClientInfoV4(to_wchar_string(server_ip_address), search_info.pointer, client_info_ptr_ptr)
      if is_error?(error)
        unless (client_info_ptr_ptr.null? || (to_free = client_info_ptr_ptr.read_pointer).null?)
          free_memory(DhcpsApi::DHCP_CLIENT_INFO_V4.new(to_free))
        end
        raise DhcpsApi::Error.new("Error retrieving client '%s'." % [client_id], error)
      end

      client_info = DhcpsApi::DHCP_CLIENT_INFO_V4.new(client_info_ptr_ptr.read_pointer)
      to_return = client_info.as_ruby_struct

      free_memory(client_info)
      to_return
    end

    def dhcp_enum_subnet_clients_v4(subnet_address, preferred_maximum, resume_handle)
      resume_handle_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, resume_handle)
      client_info_ptr_ptr = FFI::MemoryPointer.new(:pointer)
      elements_read_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, 0)
      elements_total_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, 0)

      error = DhcpsApi::Win2008::Client.DhcpEnumSubnetClientsV4(
          to_wchar_string(server_ip_address), ip_to_uint32(subnet_address), resume_handle_ptr, preferred_maximum,
          client_info_ptr_ptr, elements_read_ptr, elements_total_ptr)
      return empty_response if error == 259
      if is_error?(error)
        unless (client_info_ptr_ptr.null? || (to_free = client_info_ptr_ptr.read_pointer).null?)
          free_memory(DhcpsApi::DHCP_CLIENT_INFO_ARRAY_V4.new(to_free))
        end
        raise DhcpsApi::Error.new("Error retrieving clients from subnet '%s'." % [subnet_address], error)
      end

      leases_array = DhcpsApi::DHCP_CLIENT_INFO_ARRAY_V4.new(client_info_ptr_ptr.read_pointer)
      leases = leases_array.as_ruby_struct
      free_memory(leases_array)

      [leases, resume_handle_ptr.get_uint32(0), elements_read_ptr.get_uint32(0), elements_total_ptr.get_uint32(0)]
    end

    def dhcp_v4_enum_subnet_clients(subnet_address, preferred_maximum, resume_handle)
      resume_handle_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, resume_handle)
      client_info_ptr_ptr = FFI::MemoryPointer.new(:pointer)
      elements_read_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, 0)
      elements_total_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, 0)

      error = DhcpsApi::Win2012::Client.DhcpV4EnumSubnetClients(
          to_wchar_string(server_ip_address), ip_to_uint32(subnet_address), resume_handle_ptr, preferred_maximum,
          client_info_ptr_ptr, elements_read_ptr, elements_total_ptr)
      return empty_response if error == 259
      if is_error?(error)
        unless (client_info_ptr_ptr.null? || (to_free = client_info_ptr_ptr.read_pointer).null?)
          free_memory(DhcpsApi::DHCP_CLIENT_INFO_PB_ARRAY.new(to_free))
        end
        raise DhcpsApi::Error.new("Error retrieving clients from subnet '%s'." % [subnet_address], error)
      end

      leases_array = DhcpsApi::DHCP_CLIENT_INFO_PB_ARRAY.new(client_info_ptr_ptr.read_pointer)
      lease_infos = (0..(leases_array[:num_elements]-1)).inject([]) do |all, offset|
        all << DhcpsApi::DHCP_CLIENT_INFO_PB.new((leases_array[:clients] + offset*FFI::Pointer.size).read_pointer)
      end

      leases = lease_infos.map {|lease_info| lease_info.as_ruby_struct}
      free_memory(leases_array)

      [leases, resume_handle_ptr.get_uint32(0), elements_read_ptr.get_uint32(0), elements_total_ptr.get_uint32(0)]
    end
  end
end
