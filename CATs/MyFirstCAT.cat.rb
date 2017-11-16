name "My First CloudApp"
rs_ca_ver 20161221
short_description "This is my first CloudApp.  It will launch a single Linux Server"

resource "my_first_server", type: "server" do
  name "My First Server"
  cloud "EC2 us-west-2"
  security_groups "default"
  ssh_key "default"
  server_template find("Base ServerTemplate for Linux (v14.1.1)", revision: 68)
end
