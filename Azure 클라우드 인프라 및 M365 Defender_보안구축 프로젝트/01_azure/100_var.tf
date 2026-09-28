variable "subid" {
  type = string
}

variable "rgname" {
  type = string
}

variable "loca" {
  type = string
}

variable "hubcidr" {
  type = string
}

variable "webspokecidr" {
  type = string
}

variable "fwsub" {
  type = string
}

variable "appgwsub" {
  type = string
}

variable "vpngwsub" {
  type = string
}

variable "batsub" {
  type = string
}

variable "websub" {
  type = string
}

variable "webPEsub" {
  type = string
}

variable "dbspokecidr" {
  type = string
}

variable "dbsub" {
  type = string
}

variable "wassub" {
  type = string
}

variable "onprem_gateway_ip" {
  type = string
}

variable "onprem_cidr" {
  type = string
}

variable "vpn_shared_key" {
  type      = string
  sensitive = true
}

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "onprem_mysql_host" {
  type = string
}

variable "mysql_server_name" {
  type = string
}

variable "tm_profile" {
  type    = bool
  default = false
}

variable "tm_priority" {
  type    = number
  default = 1
}

variable "appgw_dns_label" {
  type = string
}

variable "waslbip" {
  type = string
}

variable "admin_cidr" {
  type = string
}

variable "onprem_elk_host" {
  type = string
}

variable "github_user" {
  type    = string
  default = "o12ryan"
}

variable "github_repo" {
  type    = string
  default = "https://github.com/o12ryan/team4project-2.git"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "app_db_name" {
  type    = string
  default = "emp_db"
}

variable "app_db_user" {
  type    = string
  default = "emp_user"
}