require 'spec_helper'

describe 'razor::hook', :type => :define do
  Puppet::Util::Log.level = :warning
  Puppet::Util::Log.newdestination(:console)

  on_supported_os(
    :supported_os => [
      {
        "operatingsystem" => "Ubuntu",
        "operatingsystemrelease" => [
          "14.04",
          "16.04"
        ]
      },
      {
        "operatingsystem" => "CentOS",
        "operatingsystemrelease" => [
          "6.5",
          "7.0.1406"
        ]
      },
    ]
  ).each do |os, facts|  
    context "on #{os}" do        
      let(:facts) { 
        facts
      }
        
      let(:title) { 'puppetcert' }
      
      context "defaults" do    
        let(:pre_condition) { 
          dependencies() + razor_default()
        }
        
        it { should compile.with_all_deps }
          
        it { should contain_file('/opt/razor/hooks/puppetcert.hook').with(
          'source' => "puppet:///modules/razor/hooks/puppetcert.hook"
        ) }
      end
      
      context "aio_support" do    
        let(:pre_condition) { 
          dependencies() + razor_default_aio()
        }
        
        it { should compile.with_all_deps }
          
        it { should contain_file('/opt/puppetlabs/server/apps/razor-server/share/razor-server/hooks/puppetcert.hook').with(
          'source' => "puppet:///modules/razor/hooks/puppetcert.hook"
        ) }
      end
    end
  end
end
