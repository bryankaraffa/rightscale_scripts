name              "Custom ServerArray Launch"
short_description "Demonstrates how to define a custom procedure for the CloudApp to provision a ServerArray its instances on launch"
rs_ca_ver         20160622

resource 'my_first_serverarray', type: 'server_array' do
  name "My First ServerArray"
  cloud "EC2 us-west-2"
  security_groups "default"
  ssh_key "default"
  server_template find("Base ServerTemplate for Linux (v14.1.1)", revision: 68)
  state                'disabled'
  array_type            'alert'
  elasticity_params do {
    'bounds' => {
      'min_count'            => 1,
      'max_count'            => 5
    },
    'pacing' => {
      'resize_calm_time'     => 5,
      'resize_down_by'       => 1,
      'resize_up_by'         => 1
    },
    'alert_specific_params' => {
      'decision_threshold'   => 51,
      'voters_tag_predicate' => 'my_first_serverarray'
    }
  } end
end

parameter "param_server_count" do
  type "string"
  label "Server Count"
  description "Total of instances desired in Array"
  default "3"
end



operation "launch" do
  description "launch"
  definition "custom_launch"
end

define custom_launch(@my_first_serverarray, $param_server_count) return @my_first_serverarray, $param_server_count do
  # Provision the ServerArray resource and allow the first instance to go operational
  task_label("Provisioning ServerArray and launching initial instance")
  provision(@my_first_serverarray)

  # After launching the first instance, launch the rest of the instances
  task_label("Increasing ServerArray instance count to " + $param_server_count)
  call modify_instance_count(@my_first_serverarray, $param_server_count)


end




define modify_instance_count(@my_first_serverarray, $param_server_count) return @serverarray do  
  # Setup the API call parameter
  $array_inputs =  {
    elasticity_params: {
      bounds: { min_count: $param_server_count }
    }
  } 
  # Update min-count on the array
  sub timeout: 10m do
    task_label("Updating ServerArray Instance Minimum Count")
    @my_first_serverarray.update(server_array: $array_inputs)
    # Wait until new instances are launched before checking if they are all operational
    task_label("Waiting for array to scale to new size")
    sleep_until equals?(to_n(@my_first_serverarray.instances_count), to_n($param_server_count))
  end
  # Double-check that all instances are operational before exiting *or* timeout after 10minutes, whichever comes first.
  sub timeout: 10m do
    task_label("Validating all instances in array are fully operational")
    sleep_until all?(@my_first_serverarray.current_instances().state[], "operational")
  end

end


# A Custom Operation definition which allows the ServerArray size to be modified manually after the CloudApp has launched
operation "modify_instance_count" do
  label "modify_instance_count"
  description "Start additional instances in the array"
  definition "modify_instance_count"
end

