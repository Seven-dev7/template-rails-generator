class RspecInit
  require 'fileutils'

  def self.perform
    new.perform
  end

  def perform
    install_rspec  
  end

  private

  def install_rspec
    generate "rspec:install"
    faker_configuration
    factory_bot_configuration
  end
  
  def factory_bot_configuration
    inject_into_file 'spec/rails_helper.rb', after: "require 'rspec/rails'" do
      "\nrequire 'ffaker'\n"
    end
  end
  
  def faker_configuration
    inject_into_file 'spec/rails_helper.rb', after: 'gems_from_backtrace("gem name")' do
      "\nconfig.include FactoryBot::Syntax::Methods\n"
    end
  end
end
