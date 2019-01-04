require File.join(File.dirname(__FILE__), '..', 'razor_rest')

Puppet::Type.type(:razor_hook).provide :rest, :parent => Puppet::Provider::Rest do
  desc "REST provider for Razor hook"

  mk_resource_methods

  def flush
    if @property_flush[:ensure] == :absent
      delete_hook
      return
    end

    if @property_flush[:ensure] == :present
      create_hook
      return
    end

    update_hook
  end

  def self.instances
    get_objects(:hooks).collect do |object|
      new(object)
    end
  end

  # TYPE SPECIFIC
  def self.get_object(name, url)
    responseJson = get_json_from_url(url)

    {
      :name          => responseJson['name'],
      :hook_type     => responseJson['hook_type'],
      :configuration => responseJson['configuration'],
      :ensure        => :present
    }
  end

  def self.get_hook(name)
    rest = get_rest_info
    url = "http://#{rest[:ip]}:#{rest[:port]}/api/collections/hooks/#{name}"

    get_object(name, url)
  end

  private
  def create_hook
    resourceHash = {
      :name          => resource[:name],
      'hook_type'    => resource['hook_type'],
      :configuration => resource['configuration'],
    }
    post_command('create-hook', resourceHash)
  end

  def update_hook
    current_state = self.class.get_hook(resource[:name])
    updated = false

    # Configuration
    if current_state[:configuration] != @property_hash[:configuration]
      current = current_state[:configuration]
      expected = @property_hash[:configuration]

      # Update or Delete
      current.select { |k1, v1|
        found = false

        expected.select { |k2, v2|
          if k1 == k2
            if v1 != v2
              resourceHash = {
                :hook  => resource[:name],
                :key   => k1,
                :value => v2,
              }
              post_command('update-hook-configuration', resourceHash)
            end

            found = true
          end
        }

        if !found
          resourceHash = {
            :hook  => resource[:name],
            :key   => k1,
            :clear => true,
          }
          post_command('update-hook-configuration', resourceHash)
        end
      }

      # Add
      expected.select { |k1, v1|
        found = false

        current.select { |k2, v2|
          if k1 == k2
            found = true
          end
        }

        if !found
          resourceHash = {
            :hook  => resource[:name],
            :key   => k1,
            :value => v1,
          }
          post_command('update-hook-configuration', resourceHash)
        end
      }

      updated = true
    end

    if (!updated)
      # Hook does not provide an update function
      Puppet.warning("Razor REST API only provides an update function for the hook configuration.")
      Puppet.warning("Will attempt a delete and create, which will only work if the hook is not used by a policy.")

      delete_hook
      create_hook
    end

    # Update the current info
    @property_hash = self.class.get_hook(resource[:name])
  end

  def delete_hook
    resourceHash = {
      :name => resource[:name],
    }
    post_command('delete-hook', resourceHash)
  end
end
