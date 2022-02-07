class PagesControllerInit
  def self.perform
    new.perform
  end

  def perform
    page_controller_home 
  end

  private

  def page_controller_home
    generate(:controller, 'pages home')
    route "root to: 'pages#home'"
    rails_command 'db:migrate'
  end
end