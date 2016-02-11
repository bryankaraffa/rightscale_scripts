#!/bin/bash

#################################################################
# Global Cofig
rightscale_Account=78672
utilityServer_Href='/api/deployments/608115004/servers/1228456004'
rightscript_Href='/api/right_scripts/555596004'
# End Global Config
## DO NOT EDIT BELOW THIS LINE ##
# Get NAT/Utility Server's Instance HREF
function diff_packages_PreProd_vs_Prod() {
    # Get Private IPs of respective Prod/PreProd instances
    if [[ $2 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        preprod_Ip=$2
    else
        preprod_Href=$2
        preprod_Ip=`rsc cm15 show $preprod_Href --account $rightscale_Account --pp 'view=instance_detail' --x1 '.current_instance.private_ip_addresses string'`
    fi
    if [[ $3 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        prod_Ip=$3
    else
        prod_Href=$3
        prod_Ip=`rsc cm15 show $prod_Href --account $rightscale_Account --pp 'view=instance_detail' --x1 '.current_instance.private_ip_addresses string'`
    fi

    # Run Diff Script
    printf "Running diff task on $1"
    task=`rsc --account $rightscale_Account cm15 run_executable $utilityServer_instanceHref "right_script_href=$rightscript_Href" "inputs[][name]=PREPROD_PRIVATEIP" "inputs[][value]=$preprod_Ip" "inputs[][name]=PROD_PRIVATEIP" "inputs[][value]=$prod_Ip" "ignore_lock=true" --xh Location`
    while [[ ! "`rsc cm15 --account $rightscale_Account show $task 'view=extended' --x1 .summary`" =~ "completed" ]]
    do
        printf .
        sleep 5
    done
    # Print REsults
    echo " "
    echo "***** $1 *****"
    rsc cm15 --account 78672 show $task 'view=extended' --x1 .detail | grep ii 
}
utilityServer_instanceHref=`rsc cm15 show $utilityServer_Href  --account $rightscale_Account 'view=instance_detail' --x1 'object:has(.rel:val("current_instance")).href'`
## DO NOT EDIT ABOVE THIS LINE ##
#################################################################

diff_packages_PreProd_vs_Prod 'DB 001' '/api/deployments/605822004/servers/1222912004' '/api/deployments/613303004/servers/1243248004'

diff_packages_PreProd_vs_Prod 'DB 002' '/api/deployments/605822004/servers/1223031004' '/api/deployments/613303004/servers/1256690004'

diff_packages_PreProd_vs_Prod 'GLUSTER 001' '/api/deployments/605822004/servers/1222928004' '/api/deployments/613303004/servers/1235332004'

diff_packages_PreProd_vs_Prod 'GLUSTER 002' '/api/deployments/605822004/servers/1222944004' '/api/deployments/613303004/servers/1235411004'

diff_packages_PreProd_vs_Prod 'SOLR MASTER (PreProd) vs SOLR 001 (Prod)' '/api/deployments/605822004/servers/1222945004' '/api/deployments/613303004/servers/1235334004'

diff_packages_PreProd_vs_Prod 'SOLR MASTER (PreProd) vs SOLR 002 (Prod)' '/api/deployments/605822004/servers/1222945004' '/api/deployments/613303004/servers/1235755004'

diff_packages_PreProd_vs_Prod 'APPSERVER #27 (PreProd) vs APPSERVER #50 (Prod)' '10.146.0.144' '10.146.0.157'

diff_packages_PreProd_vs_Prod 'APPSERVER #27 (PreProd) vs APPSERVER #51 (Prod)' '10.146.0.144' '10.146.0.242'

diff_packages_PreProd_vs_Prod 'APPSERVER #27 (PreProd) vs APPSERVER #52 (Prod)' '10.146.0.144' '10.146.0.180'




