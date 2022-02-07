class BootstrapInit
  require 'fileutils'

  def self.perform
    new.perform
  end

  def perform
    add_bootstrap_cdn  
  end

  private

  def add_bootstrap_cdn
    inject_into_file 'app/views/layouts/application.html.erb', after: 'javascript_importmap_tags %>' do
      "\n<link href='https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css' rel='stylesheet' integrity='sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC' crossorigin='anonymous'>"
    end
    inject_into_file 'app/views/layouts/application.html.erb', after: '<%= yield %>' do
      "\n<script src='https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js' integrity='sha384-MrcW6ZMFYlzcLA8Nl+NtUVF0sA7MsXsP1UyJoMp4YLEuNSfAP+JcXn/tWtIaxVXM' crossorigin='anonymous'></script>"
    end
  end  
end