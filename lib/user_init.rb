class UserInit
  require 'fileutils'

  def self.perform
    new.perform
  end

  def perform
    setup_users
  end

  private

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

  def create_user_seed
    inject_into_file 'db/seeds.rb' do
      "\nUser.create!(email: 'email_1@email.fr', password: 'blablabla', username: 'user_1')
        p '1 user created'\n"
    end
    rails_command 'db:seed'
  end  
end