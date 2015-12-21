#!/bin/bash
# Takes 2 inputs, a path to a file containing a list of hostnames and an RS Account Number
# Returns the hostnames that match up to an IP(s) in the RS Account
#
# Example Usage:
#     $ validate_Domains_Hosted_In_RS_Account.sh 16267 sites_file.txt

# Setup the inputs
RS_ACCOUNT=$1
HOSTS_FILE=$2

# Get IPs in a RightScale Account
IFS=$'\r\n' GLOBIGNORE='*' :; managed_ips=($(rsc cm16 --account $RS_ACCOUNT index /api/instances --xm .public_ip_addresses | grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"))

# Loop through the hostname file line by line and check if any IP(s) in managed_ips[] match
while read hostname; do

    # Check if domain resolves to IP in $managed_ip[]
    IFS=$'\r\n' GLOBIGNORE='*' :; domain_ips=($(dig +short $hostname | grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"))
    if [[ " ${managed_ips[@]} " =~ " ${domain_ips[@]} " ]]; then
        echo $hostname
    #else
    #    Do nothing if hostname does not match any IPs in the RS Account
    fi
done <$HOSTS_FILE