
# frozen_string_literal: true

# Writing and Reading to files
require 'fileutils'

def add_gems
  gem 'byebug', platforms: %i(mri mingw x64_mingw)
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  gem 'dotenv-rails', '~> 2.7', '>= 2.7.6'
  gem 'factory_bot_rails', '~> 6.1', '>= 6.2'
  gem 'ffaker', '~> 2.18', '>= 2.20'
  gem 'rspec-rails', '~> 5.0', '>= 5.0.1'
  gem 'shoulda-matchers', '~> 4.5', '>= 4.5.1'
  gem 'devise'
end

def source_paths
  [__dir__]
end

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

def setup_users
  generate 'devise:install'
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'
  generate :devise, 'User', 'username:string:uniq', 'admin:boolean'
  rails_command 'db:migrate'
  generate 'devise:views'

  in_root do
    migration = Dir.glob('db/migrate/*').max_by { |f| File.mtime(f) }
    gsub_file migration, /:admin/, ':admin, default: false'
  end
  inject_into_file 'app/controllers/application_controller.rb', before: 'end' do
    "\n  before_action :configure_permitted_parameters, if: :devise_controller?
    protected
    def configure_permitted_parameters
      added_attrs = %i[username email password password_confirmation remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end\n"
  end

  inject_into_file 'app/models/user.rb', before: 'end' do
    "\n validates :username, presence: true, uniqueness: { case_sensitive: false }
      validate :validate_username
      attr_writer :login\n
      def login
        @login || username || email
      end
      def validate_username
        errors.add(:username, :invalid) if User.where(email: username).exists?
      end
      def self.find_for_database_authentication(warden_conditions)
        conditions = warden_conditions.dup
        if login = conditions.delete(:login)
            where(conditions.to_hash).where(['lower(username) = :value OR lower(email) = :value', {value: login.downcase}]).first
        elsif conditions.key?(:username) || conditions.key?(:email)
            where(conditions.to_h).first
        end
      end\n"
  end

  inject_into_file 'config/initializers/devise.rb', before: '# with default "from" parameter.' do
    "\nconfig.navigational_formats = ['*/*', :html, :turbo_stream]\n"
  end

  inject_into_file 'config/initializers/devise.rb', after: '# config.authentication_keys = [:email]' do
    "\n config.authentication_keys = [:login]\n"
  end

  find_and_replace_in_file('app/views/devise/sessions/new.html.erb', 'email', 'login')

  inject_into_file 'app/views/devise/registrations/new.html.erb', before: '<%= f.input :email' do
    "\n<%= f.input :username %>\n"
  end

  inject_into_file 'app/views/devise/registrations/edit.html.erb', before: '<%= f.input :email' do
    "\n<%= f.input :username %>\n"
  end

  complete_user_factory

  create_user_spec
end

def complete_user_factory
  inject_into_file 'spec/factories/users.rb', after: ':user do' do
    "\nemail { FFaker::Internet.email }\n
    username { FFaker::Name.unique.name }\n
    password { 'blabla' }\n"
  end
end

def create_user_spec
  inject_into_file 'spec/models/user_spec.rb', after: ':model do' do
    "\n  let(:user) { create(:user) }\n\n
    it { expect(user).to be_valid }\n"
  end
end

def find_and_replace_in_file(file_name, old_content, new_content)
  text = File.read(file_name)
  new_contents = text.gsub(old_content, new_content)
  File.open(file_name, 'w') { |file| file.write new_contents }
end

def demo_rails_commands
  generate(:controller, 'pages home')
  route "root to: 'pages#home'"
  rails_command 'db:migrate'
end

def add_bootstrap_cdn
  inject_into_file 'app/views/layouts/application.html.erb', after: 'javascript_importmap_tags %>' do
    "\n<link href='https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css' rel='stylesheet' integrity='sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC' crossorigin='anonymous'>"
  end
  inject_into_file 'app/views/layouts/application.html.erb', after: '<%= yield %>' do
    "\n<script src='https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js' integrity='sha384-MrcW6ZMFYlzcLA8Nl+NtUVF0sA7MsXsP1UyJoMp4YLEuNSfAP+JcXn/tWtIaxVXM' crossorigin='anonymous'></script>"
  end
end

def add_bootstrap_navbar
  navbar = 'app/views/layouts/_navbar.html.erb'
  FileUtils.touch(navbar)
  inject_into_file 'app/views/layouts/application.html.erb', before: '<%= yield %>' do
    "\n<%= render 'layouts/navbar' %>\n"
  end

  append_to_file navbar do
    '<nav class="navbar navbar-expand-lg navbar-light bg-light">
      <div class="container-fluid">
        <a class="navbar-brand" href="#">Navbar</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarSupportedContent">
          <ul class="navbar-nav me-auto mb-2 mb-lg-0">
            <li class="nav-item">
              <%= link_to "Home", root_path, class:"nav-link active" %>
            </li>
            <li class="nav-item dropdown">
              <% unless user_signed_in? %>
                <li class="nav-item">
                  <%= link_to "Create Account", new_user_registration_path, class:"nav-link" %>
                </li>
                <li class="nav-item">
                  <%= link_to "Login", new_user_session_path, class:"nav-link" %>
                </li>
              <% else %>
                <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                  <%= current_user.username %>
                </a>
                <ul class="dropdown-menu" aria-labelledby="navbarDropdown">
                  <li><%= link_to "Account Settings", edit_user_registration_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Logout", destroy_user_session_path, data: { "turbo-method": :delete } , class: "dropdown-item"%></li>
                  <li><hr class="dropdown-divider"></li>
                  <li><a class="dropdown-item" href="#">Something else here</a></li>
                </ul>
              <% end %>
            </li>
        </div>
      </div>
    </nav>'
  end
end

def create_user_seed
  inject_into_file 'db/seeds.rb' do
    "\nUser.create!(email: 'email_1@email.fr', password: 'blablabla', username: 'user_1')
      p '1 user created'\n"
  end
  rails_command 'db:seed'
end

def drop_and_create_db
  rails_command 'db:drop'
  rails_command 'db:create'
end

source_paths

add_gems

after_bundle do
  drop_and_create_db
  install_rspec
  setup_users
  create_user_seed

  demo_rails_commands

  add_bootstrap_cdn
  add_bootstrap_navbar
end