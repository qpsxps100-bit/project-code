# ── 서비스 관리자 역할 ──
# 실습 계정(RBAC Administrator)은 역할 "정의 생성"(roleDefinitions/write) 권한이 없어
# 커스텀 역할을 만들 수 없으므로, 내장(Built-in) 역할만 할당한다.

locals {
  cso_admin_single = var.cso
  security_admins= concat(var.cso, var.security_admins)
  infra_admins = concat(var.cso, var.infra_admins)
  service_admins = concat(var.cso, var.service_admins)
}

# 최고보안관리자 : 두 그룹에 대한 owner 권한
resource "azurerm_role_assignment" "cso_sec_rg_owner" {
  for_each             = toset(local.cso_admin_single)
  scope                = azurerm_resource_group.security.id
  role_definition_name = "Owner"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "cso_infra_rg_owner" {
  for_each             = toset(local.cso_admin_single)
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Owner"
  principal_id         = each.value
}

# ── 보안 관리자 ── : security group 에 대한 contributor 

# 그룹 관련
resource "azurerm_role_assignment" "sec_rg_contributor" {
  for_each             = toset(local.security_admins)
  scope                = azurerm_resource_group.security.id
  role_definition_name = "Contributor"
  principal_id         = each.value
}

# key vault
resource "azurerm_role_assignment" "sec_kv_admin" {
  for_each             = toset(local.security_admins)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

# sentinel
resource "azurerm_role_assignment" "sec_sentinel" {
  for_each             = toset(local.security_admins)
  scope                = azurerm_log_analytics_workspace.main.id
  role_definition_name = "Microsoft Sentinel Contributor" # 쿼리 실행용
  principal_id         = each.value
}

# monitor
resource "azurerm_role_assignment" "sec_monitor" {
  for_each             = toset(local.security_admins)
  scope                = azurerm_log_analytics_workspace.main.id
  role_definition_name = "Monitoring Contributor" 
  principal_id         = each.value
}

resource "azurerm_role_assignment" "sec_storage" {
  for_each             = toset(local.security_admins)
  scope                = azurerm_storage_account.security.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

# logic app
resource "azurerm_role_assignment" "sec_logicapp" {
  for_each = toset(local.security_admins)
  scope = azurerm_logic_app_workflow.autoblock.id
  role_definition_name = "Logic App Contributor"
  principal_id = each.value
}

### ── 인프라 관리자 ──
resource "azurerm_role_assignment" "infra_rg_contributor" {
  for_each             = toset(local.infra_admins)
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Contributor"
  principal_id         = each.value
}

# vm 관련
resource "azurerm_role_assignment" "infra_vm_admin_login" {
  for_each             = toset(local.infra_admins)
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = each.value
}

# ── 서비스 관리자 (내장 역할만, 운영·조회 전용 / 보안 설정 변경 불가) ──
resource "azurerm_role_assignment" "svc_vm_operator" {
  for_each             = toset(local.service_admins)
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Reader"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "svc_vm_login" {
  for_each             = toset(local.service_admins)
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = each.value
}

# DB는 조회만 (시작/중지 커스텀 권한은 못 만들어 Reader로 대체)
resource "azurerm_role_assignment" "svc_db_reader" {
  for_each             = toset(local.service_admins)
  scope                = azurerm_mysql_flexible_server.main.id
  role_definition_name = "Reader"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "svc_monitoring_reader" {
  for_each             = toset(local.service_admins)
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Monitoring Reader"
  principal_id         = each.value
}
