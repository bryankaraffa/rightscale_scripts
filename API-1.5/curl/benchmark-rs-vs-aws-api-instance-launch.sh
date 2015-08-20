#!/bin/bash
#
#  Compares the time it takes for a raw instance to be launched when
#  using the RS API vs Cloud API [EC2 and GCE]
#

# Global Parameters

## AWS Account Credentials
AWS_ACCESS_KEY=${AWS_ACCESS_KEY:='ABC__replace_with_aws_access_key_XYZ'}
AWS_SECRET_KEY=${AWS_SECRET_KEY:='123XYZ__replace_with_aws_secret_key__XXX'}

## RightScale Account Credentials
RS_EMAIL=${rs_email:='your@email.com'}     	# RS User Account
RS_PASSWORD=${rs_pswd:='yourpassword'}      # RS User Password
RS_ACCT=${rs_acct:='12345'}             	# RS Account ID


# Functions
launchInstanceUsingRS(){
	## Execute API Call to retrieve cookie and save it to mycookie
	curl -s -l -H X_API_VERSION:1.5 -c mycookie \
	-d email="$RS_EMAIL" \
	-d password="$RS_PASSWORD" \
	-d account_href="/api/accounts/$RS_ACCT" \
	-X POST https://my.rightscale.com/api/session
	
	
	rs_startTime=`date +%s`
	## Launch Instance and get the resource_uid
	instance_href="$(curl -s -i -l -H X_API_VERSION:1.5 -b mycookie \
	-d instance[image_href]='/api/clouds/1/images/BT0FJ9DJ8VOJ4' \
	-d instance[ssh_key_href]='/api/clouds/1/ssh_keys/9AQBF50L4A8O5' \
	-d instance[instance_type_href]='/api/clouds/1/instance_types/CQQV62T389R32' \
	-d instance[name]='Test-Raw-Instance_fromRSAPI' \
	-X POST https://my.rightscale.com/api/clouds/1/instances | grep "Location: /api/clouds/")"
	instance_href="${instance_href:10}"
	instance_href="$(echo -e "${instance_href}" | tr -d '[[:space:]]')"
	InstanceResourceId=`/home/bryankaraffa/Applications/rsc/rsc --x1 .resource_uid cm15 show ${instance_href}`


	## Wait for instance to pass AWS status checks	
	rs_launch_in_progress="true"
	while [ "$rs_launch_in_progress" == "true" ]
	do		
		read -a responseArray <<< $(ec2-describe-instance-status $InstanceResourceId)
		
		if [ "${responseArray[5]}" == "ok" ] && [ "${responseArray[6]}" == "ok" ] && [ "${responseArray[10]}" == "passed" ] && [ "${responseArray[13]}" == "passed" ]
		then
			rs_launch_in_progress=false
		fi
	done
		
	rs_endTime=`date +%s`
	rs_launchTime=`expr $rs_endTime - $rs_startTime`
	echo $rs_launchTime > rs_launchTime.txt	
}

launchInstanceUsingEC2(){
	ec2_startTime=`date +%s`
	
	# ubuntu/images/ubuntu-precise-12.04-amd64-server-20150819 - ami-ef6cdc84
	# Root device type: instance-store Virtualization type: paravirtual
	# ---
	# ubuntu/images/hvm-instance/ubuntu-precise-12.04-amd64-server-20150819 - ami-2155e54a
	# Root device type: instance-store Virtualization type: hvm
	ImageId='ami-ef6cdc84'
	KeyName='bk-test-ssh-key'
	InstanceType='m1.small'

	#Launch the instance and get resource id from response
	read -a response <<< $(ec2-run-instances -v $ImageId -k $KeyName -t $InstanceType --aws-access-key $AWS_ACCESS_KEY --aws-secret-key $AWS_SECRET_KEY | grep 'INSTANCE')
	InstanceResourceId=${response[1]}
	
	ec2_launch_in_progress="true"
	while [ "$ec2_launch_in_progress" == "true" ]
	do		
		read -a responseArray <<< $(ec2-describe-instance-status $InstanceResourceId)
		
		if [ "${responseArray[5]}" == "ok" ] && [ "${responseArray[6]}" == "ok" ] && [ "${responseArray[10]}" == "passed" ] && [ "${responseArray[13]}" == "passed" ]
		then
			ec2_launch_in_progress=false
		fi
	done
	ec2_endTime=`date +%s`
	ec2_launchTime=`expr $ec2_endTime - $ec2_startTime`
	echo $ec2_launchTime > ec2_launchTime.txt
}

#  Begin the Benchmark
clear
touch rs_launchTime.txt
touch ec2_launchTime.txt

launchInstanceUsingEC2 &
launchInstanceUsingRS &
wait

# Print Results
echo ""
echo "----- Results -----"
echo 'EC2 API Launch Time in seconds:'
cat ec2_launchTime.txt
echo 'RS API Launch Time in seconds:'
cat rs_launchTime.txt
echo '----- ------- -----'
echo "$(date +%s) $(cat ec2_launchTime.txt) $(cat rs_launchTime.txt)" >> benchmarks.log
echo 'Done!'