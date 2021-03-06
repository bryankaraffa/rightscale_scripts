#!/usr/bin/env ruby

require 'rubygems'
require 'right_api_client'



# Primary Inputs
email = ENV['rs_email'] || 'your@email.com'          # RS User Account
pass = ENV['rs_pswd'] || 'yourpassword'              # RS User Password
acct_id = ENV['rs_acct'] || '12345'                  # RS Account to backup scripts from


# Optional Inputs
timeout = ENV['rs_timeout'] || 60                    # Timeout in Seconds
backup_location = ENV['rs_backup_location'] || '.'   # Backup location - NO trailing slash

puts ENV.has_key?('rs_email') ? 'rs_email set by ENVIRONMENT' : 'rs_email set by SCRIPT [default]'
puts ENV.has_key?('rs_pswd') ? 'rs_pswd set by ENVIRONMENT' : 'rs_pswd set by SCRIPT [default]'
puts ENV.has_key?('rs_acct') ? 'rs_acct set by ENVIRONMENT' : 'rs_acct set by SCRIPT [default]'


# Authenticate
@client = RightApi::Client.new(:email => email, :password => pass, :account_id => acct_id, :timeout => timeout.to_i )

puts "Authenticated!"

puts "Backing up RightScripts using user: #{email} for RightScale Account: #{acct_id} to Location: #{backup_location}"

@client.right_scripts.index.each do |rs|
  href = "http://my.rightscale.com#{rs.href}/source"

  detail_req = RestClient::Request.new(
    :url => href,
    :method => :get,
    :cookies => @client.cookies,
    :headers => {"X_API_VERSION"=>"1.5"}
  )
  detail_resp = detail_req.execute

  backup_file = "#{backup_location}/#{rs.name.to_s.gsub("/", " ").gsub('\\', " ")}.#{rs.href.split('/').last}.sh"
  #puts detail_resp.body
  File.open(backup_file, 'w') do |f2|
    f2.puts detail_resp.body
    f2.puts '### This script was backed up automatically ###'
    f2.puts "#   "
    f2.puts "#   RightScript Name: #{rs.name.to_s}"
    f2.puts "#   RightScript HREF: #{rs.href}"
    f2.puts "#   "
  end
  puts backup_file
end
