class NavbarPartialInit
  require 'fileutils'

  def self.perform
    new.perform
  end

  def perform
    add_bootstrap_navbar  
  end

  private

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
end