class DbInit
  def self.perform
    new.perform
  end

  def perform
    rails_command 'db:drop'
    rails_command 'db:create'  
  end
end
