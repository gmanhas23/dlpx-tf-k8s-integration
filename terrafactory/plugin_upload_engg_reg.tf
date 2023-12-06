terraform {
  required_version = ">= 1.2.0"
}

resource "null_resource" "plugin_upload" {
 provisioner "local-exec" {
    command = "/bin/bash plugin_upload.sh engine-gm.dlpxdc.co"
  }
}

resource "null_resource" "register_engine" {
 provisioner "local-exec" {
    command = "/bin/bash reg_engg.sh engine-gm.dlpxdc.co"
  }
}
