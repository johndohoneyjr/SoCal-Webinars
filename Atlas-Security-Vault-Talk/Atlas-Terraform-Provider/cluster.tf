terraform {
  required_version = ">= 0.12"
}

data "vault_generic_secret" "mongodbatlas_secret" {
  path = "mongodbatlas/creds/cicd-mongodb"
}

#
# Configure the MongoDB Atlas Provider
#
provider "mongodbatlas" {
   public_key  = "${ data.vault_generic_secret.mongodbatlas_secret.data["public_key"]  }"
   private_key = "${ data.vault_generic_secret.mongodbatlas_secret.data["private_key"] }"
}


#
# Create a Project 
#
resource "mongodbatlas_project" "my_project" {
  name 			= "DevOps-Demo"
  org_id		= "${var.mongodb_atlas_org_id}"
}

#
# Create a Cluster in 2 Regions
#
resource "mongodbatlas_cluster" "cluster" {
  name                        	= "DevOps-Multi"
  project_id                  	= "${mongodbatlas_project.my_project.id}"
  backup_enabled		            = false
  auto_scaling_disk_gb_enabled	= false
  mongo_db_major_version 	      = "4.0"
  cluster_type   		            = "REPLICASET"
  provider_name               	= "AWS"
  disk_size_gb			            = 100
  provider_disk_iops		        = 300
  provider_instance_size_name   = "M30"
  provider_backup_enabled 	    = true

  replication_specs {
    num_shards	    		= 1
    regions_config {
      region_name     		= "US_WEST_1"
      priority        		= 7
      read_only_nodes 		= 0 
      analytics_nodes 		= 1
      electable_nodes 		= 3
    }
  }
}

#
# Create a Database User
#
resource "mongodbatlas_database_user" "test" {
  username 	    	= "${var.database_username2}"
  password 	 	    = "${var.database_user_password2}"
  project_id      = "${mongodbatlas_project.my_project.id}"
  auth_database_name	 	= "admin"

  roles {
    role_name     	= "readWriteAnyDatabase"
    database_name 	= "admin"
  }
}

#
# Create an IP Whitelist
#

resource "mongodbatlas_project_ip_whitelist" "test" {
  project_id      = "${mongodbatlas_project.my_project.id}"  
  ip_address 	  	= "${var.mongodb_atlas_whitelistip}"
  comment     		= "Whitelist Entry for Terraform Demo"
}