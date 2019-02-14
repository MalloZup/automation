#!/usr/bin/env ruby

require "json"
# this script is called by caasp-devenv


# helper function for reading json
def get_master_and_worker_from_caasp_env
  file = File.read '../environment.json.example'
  caasp_env = JSON.parse(file)
  [count_role(caasp_env, 'master'), count_role(caasp_env, 'worker')]
end

# helper function for determine the number of role in json
def count_role(caasp_env, role)
  count_role = 0
  caasp_env['minions'].each do |salt_min|
	if role == salt_min['role']
		count_role = count_role + 1
	end
  end
  count_role
end

# parse the json for determine a list of vms used
# it will return a list of all caasp-kvm, within we do snapshot operation
def get_caasp_vms
  num_masters, num_workers = get_master_and_worker_from_caasp_env
  caasp_vms = ['admin']
  for i in (0..num_masters-1)
  	caasp_vms.push("master_#{i.to_s}")
  end
  
  for i in (0..num_workers-1)
  	caasp_vms.push("worker_#{i.to_s}")
  end
  caasp_vms
end

def main
  action = ARGV[0]
  caasp_vms = get_caasp_vms
  case action
  when 'create'
    create_snapshots(caasp_vms)
  when 'delete'
    delete_snapshots(caasp_vms)
  when 'revert'
    revert_snapshots(caasp_vms)
  else
    puts 'no valida snapshot action'
  end
end

# LIBVIRT RELATED functions
def create_snapshots(caasp_vms)
  caasp_vms.each do |caasp_vm|
    puts "creating snapshot for #{caasp_vm}"
    snapshot_name="#{caasp_vm}-base"
    `virsh snapshot-create-as --domain "#{caasp_vm}" --name "#{snapshot_name}"`
  end
end

def delete_snapshots(caasp_vms)
  caasp_vms.each do |caasp_vm|
    puts "deleting snapshot for #{caasp_vm}"
    snapshot_name="#{caasp_vm}-base"
    `virsh snapshot-delete --domain "#{caasp_vm}" --snapshotname "#{snapshot_name}"`
  end
end

def revert_snapshots(caasp_vms)
  caasp_vms.each do |caasp_vm|
    puts "reverting snapshot for #{caasp_vm}"
    snapshot_name="#{caasp_vm}-base"
    `virsh snapshot-revert "#{caasp_vm}" #{snapshot_name}`
  end
end

main
