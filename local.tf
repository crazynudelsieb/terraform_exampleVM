locals {
  tags = {
    owner       = "md"
    deployment  = "${var.resource_identifier001}"
    environment = "${var.resource_status001}"
    region      = "${var.resource_location001}"
    id          = "${random_id.randomid001.hex}"
    costcenter  = "core"
    dickbutt    = "approves"
    kums        = "1234567"
    maintenance = "Week1"
    reboot      = "auto"
  }
}
