# Install Delphix and Helm providers
terraform {
  required_providers {
    delphix = {
      version = "3.1.0"
      source  = "delphix-integrations/delphix"
    }

    helm = {
          source = "hashicorp/helm"
          version = "2.12.1"
        }

    time = {
          source = "hashicorp/time"
          version = "0.9.2"
        }
    restapi = {
          source = "Mastercard/restapi"
          version = "1.18.2"
        }
  }
}

# Configure the Delphix provider
provider "delphix" {
  tls_insecure_skip = true
  key = "1.pvR2JlMe9MEWHHV38yhNPbGMOHV9W1R2iiGYguXXSgskSIlAlyeNxiDmESFGNBLC"
  host = "dct101.dlpxdc.co"
}

# Configure the Helm provider
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Configure the Time provider
provider "time" {
  # Configuration options
}

# Configure the RestApi provider
provider "restapi" {
  uri                  = "https://dct101.dlpxdc.co"
  write_returns_object = true
  create_returns_object = false
  debug                = true

  headers = {
    "Authorization" = "apk 1.pvR2JlMe9MEWHHV38yhNPbGMOHV9W1R2iiGYguXXSgskSIlAlyeNxiDmESFGNBLC",
    "Content-Type" = "application/json"
  }

  insecure = true
  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}

locals {
    host_name = "srgt-host.dlpxdc.co"
}

#Add Surrogate/Staging host environment
resource "delphix_environment" "surrogate_host" {
     engine_id = jsondecode(file("output.json")).id
     os_name = "UNIX"
     username = "postgres"
     password = "postgres"
     hostname = local.host_name
     toolkit_path = "/var/tmp"
     name = local.host_name
     nfs_addresses = [local.host_name]
     description = "This is a surrogate host for the kubernetes driver deployment"
}

resource "restapi_object" "get_source" {
  depends_on = [delphix_environment.surrogate_host]
  object_id = "id"
  path = "/v3/sources/search?limit=50&sort=id"
  data = "{\"filter_expression\": \"name CONTAINS 'Empty CSI Volume' AND environment_id CONTAINS '${delphix_environment.surrogate_host.id}'\"}"
}

locals {
  source_id = jsondecode(restapi_object.get_source.api_response).items[0].id
}

# Create the dSource and copy data to mount path
resource "delphix_appdata_dsource" "create_dsource" {
  depends_on = [restapi_object.get_source]
  source_value               = local.source_id
  group_id                   = "K8s-dsrc"
  log_sync_enabled           = false
  make_current_account_owner = true
  link_type                  = "AppDataStaged"
  name                       = "tf-test"
  staging_mount_base         = ""
  environment_user           = "postgres"
  staging_environment        = delphix_environment.surrogate_host.id
  parameters = jsonencode({
    mount_location : "/mnt/tf-test"
  })
  sync_parameters = jsonencode({
    resync = true
  })
  ops_post_sync {
    name    = "copy cmd"
    command = "cp -r /var/lib/pgsql/12.5/data/* /mnt/tf-test"
    shell   = "shell"
  }
}

# Take snapshot of dsource
resource "null_resource" "take_dsource_snapshot" {
 depends_on = [delphix_appdata_dsource.create_dsource]
 provisioner "local-exec" {
    command = "/bin/bash take_snapshot.sh ${delphix_appdata_dsource.create_dsource.id}"
  }
}

# Create the namespace for helm installation
resource "null_resource" "create_namespace" {
  depends_on = [null_resource.take_dsource_snapshot]
  provisioner "local-exec" {
    command = "microk8s.kubectl create ns hubs-driver"
  }
}

# Define the Helm release resource
resource "helm_release" "delphix_k8s_driver" {
  depends_on = [null_resource.create_namespace]
  name       = "delphix-k8s-driver"

  # Path to Chart.yaml
  chart      = "../delphix-k8s-driver-v1.0.0/delphix-k8s-driver"

  # Path top values.yaml
  values = ["${file("../delphix-k8s-driver-v1.0.0/values.yaml")}"]
  namespace = "hubs-driver"
}

# Create the PVC from the dsource
resource "null_resource" "create_pvc" {
  depends_on = [helm_release.delphix_k8s_driver]
  provisioner "local-exec" {
    command = "microk8s.kubectl apply -f ../manifests/test-vdb.yaml"
  }
}

# Wait 60 seconds for the PVC to be created and to be usable
resource "time_sleep" "wait_60_seconds" {
  depends_on = [null_resource.create_pvc]

  create_duration = "60s"
}

resource "null_resource" "deploy_container_pod" {
  depends_on = [time_sleep.wait_60_seconds]
  provisioner "local-exec" {
    command = "microk8s.kubectl apply -f ../manifests/postgres-container.yaml"
  }
}

