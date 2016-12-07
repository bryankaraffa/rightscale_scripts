name              "Manually Enabled Array"
short_description "Example Manually Enabled Array CloudApp"
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


operation "add_instances" do
  label "Add Instances"
  description "Start additional instances in the array"
  definition "add_instances"
end
define add_instances(@my_first_serverarray, $param_server_count) return @my_first_serverarray do  
  $array_inputs =  {
    elasticity_params: {
      bounds: { min_count: $param_server_count }
    }
  } 
  @my_first_serverarray.update(server_array: $array_inputs)
end