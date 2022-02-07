Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }

class Template
  require 'fileutils'

  def self.perform
    new.perform
  end

  def perform
    source_paths
    global_installation
  end

  private

  def source_paths
    [__dir__]
  end
  
  def global_installation
    gem_init
    after_bundle do
      DbInit.perform
      RspecInit.perform
      UserInit.perform
      BootstrapInit.perform
      NavbarPartialInit.perform
      PagesControllerInit.perform
    end
  end

  def gem_init
    gem 'byebug', platforms: %i(mri mingw x64_mingw)
    gem 'debug', platforms: %i[ mri mingw x64_mingw ]
    gem 'dotenv-rails', '~> 2.7', '>= 2.7.6'
    gem 'factory_bot_rails', '~> 6.1', '>= 6.2'
    gem 'ffaker', '~> 2.18', '>= 2.20'
    gem 'rspec-rails', '~> 5.0', '>= 5.0.1'
    gem 'shoulda-matchers', '~> 4.5', '>= 4.5.1'
    gem 'devise'
  end
end

Template.perform
