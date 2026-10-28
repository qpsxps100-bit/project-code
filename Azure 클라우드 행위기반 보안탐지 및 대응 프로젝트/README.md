# Azure 클라우드 행위 기반 보안탐지 및 대응

> **인원** 팀 프로젝트 (4명) · **역할** 팀장 — 총괄 · 아키텍처 설계 · Terraform 모듈화 · 탐지 규칙/자동 대응 설계
> **핵심** Hub-Spoke 3-Tier · WAF · Microsoft Sentinel · Logic App 자동/수동 차단(SOAR)

경계 중심 방어만으로는 막기 어려운 **내부 행위 기반 위협**까지 탐지·대응하기 위한 프로젝트입니다. 3-Tier 웹 서비스(Web·WAS·DB)와 Hub-Spoke 네트워크, WAF를 기반으로 외부 공격을 차단하고, 여기에 **Microsoft Sentinel 분석 규칙 14종(외부 7 · 내부 7)** 과 **Logic App 자동/수동 대응**을 더해 내부 권한 오남용·데이터 반출 시도까지 탐지하고 대응하도록 구성했습니다. 전체 인프라는 Terraform(IaC)으로 자동화했습니다.

## 🧱 사용 기술

| 영역 | 기술 |
|---|---|
| 클라우드 / IaC | Microsoft Azure (Korea Central), Terraform (azurerm ~> 4.0) |
| 네트워크 | Hub-Spoke VNet, VNet Peering, UDR → Azure Firewall(egress 허용목록) |
| 보안 경계 | Application Gateway WAF_v2(OWASP 3.2, Prevention), NSG, Azure Bastion |
| 컴퓨트 / 서비스 | Web VM(nginx), WAS VM(Flask + gunicorn), 3-Tier |
| 데이터 | Azure MySQL Flexible Server(위임 서브넷 + Private DNS, TLS 강제) |
| 비밀 관리 | Key Vault(DB 비밀번호·TLS 인증서·SSH 키) + 관리 ID(Managed Identity) |
| 탐지 / 로그 | Log Analytics, Azure Monitor Agent(DCR), Microsoft Sentinel(분석 규칙 14종 · Hunting Query) |
| 자동 대응 | Logic App(SOAR) — WAF AutoBlockedIP 자동 추가, 수동 차단 Playbook |
| 접근 통제 | Entra ID RBAC 역할 분리(보안·인프라·서비스), 최소 권한 |

## 🏗️ 아키텍처 개요

- **Hub-Spoke** — Hub VNet(10.10.0.0/16) ↔ Spoke VNet(10.20.0.0/16) Peering, Spoke 아웃바운드는 UDR로 Azure Firewall 강제 경유
- **단일 진입점** — Application Gateway WAF_v2(HTTPS 443, OWASP 3.2 Prevention)만 공개, 인증서는 Key Vault에서 관리 ID로 로드
- **3-Tier** — Web(nginx, 정적 서빙 + 동적 프록시) → WAS(Flask/gunicorn, 로그인·회원가입) → MySQL(사설 접근만)
- **탐지** — WAF·Firewall·Bastion·MySQL 로그 + VM Syslog/auditd(FIM)를 Log Analytics로 수집, Sentinel 14종 규칙으로 외부 공격·내부 행위 탐지
- **대응** — 외부 공격 IP는 Logic App이 WAF 차단목록에 자동 추가, 내부 위협 7종은 인시던트 발생 후 수동 SOAR Playbook으로 대응
- **통제** — 관리자 역할(보안/인프라/서비스) 분리 + 최소 권한, 비밀정보는 Key Vault에만 내부화

## 📁 파일 구조

```
00_init.tf            # Provider / 버전
01_rg.tf ~ 11_route.tf    # RG · VNet · Subnet · Peering · NSG · Bastion · Firewall · UDR
12_keyvault.tf        # Key Vault + 관리 ID (DB PW · 인증서 · SSH 키)
13_appgw.tf           # Application Gateway WAF_v2 (OWASP 3.2)
14_webvm.tf / 15_wasvm.tf  # Web(nginx) / WAS(Flask+gunicorn) VM
16_private_dns.tf / 17_sqldb.tf   # MySQL Flexible + Private DNS
18_log_analytics.tf ~ 22_vm_monitoring.tf   # 로그 수집 · 진단 · RBAC · 모니터링
23_sentinel_rules.tf          # 외부 공격 분석 규칙 (7종)
28_sentinel_internal_rules.tf # 내부 행위 분석 규칙 (7종)
24_notification.tf            # 인시던트 → 메일 알림
25_autoblock.tf / 29_playbook.tf  # Logic App 자동 차단 / 수동 SOAR Playbook
26_hunting.tf                 # Hunting Query
27_activity_diag.tf / 99_outputs.tf
web_cloudinit.yaml / was_cloudinit.yaml   # 부팅 자동 구성
id_rsa.pub                    # VMSS 공개키 (개인키는 미포함)
```

## 🚀 사용 방법

```bash
# 1) 변수 파일 준비 (비밀값 채우기)
cp 100_var.tf.example 100_var.tf
#   REPLACE_WITH_... (구독 ID, Entra Object ID, PFX 비밀번호, 알림 메일 등)을 실제 값으로 수정

# 2) SSH 키페어 생성 (개인키는 커밋 금지)
ssh-keygen -t rsa -b 4096 -f ./id_rsa

# 3) TLS 인증서(team4-fullchain.pfx) 준비 후 pfx_path / pfx_password 지정

# 4) 배포
terraform init
terraform plan
terraform apply
```

## 🔐 보안 관리 기준

- DB 비밀번호 · TLS 인증서 · SSH 개인키는 **Key Vault에만 보관**하고, 코드에는 관리 ID로 참조합니다.
- 개인키(`id_rsa`), 인증서(`*.pfx`), `terraform.tfstate`, 실제 값이 담긴 `100_var.tf`, `*.tfvars`는 **`.gitignore`로 커밋에서 제외**합니다.
- 저장소에는 값이 비워진 `100_var.tf.example`과 공개키(`id_rsa.pub`)만 포함됩니다.

## 🔭 한계 및 고도화 방향

- **RBAC** — 실습 계정에 역할 정의 권한이 없어 사용자 지정 역할(VM-Operator·DB-Operator) 생성은 미적용. 향후 최소 권한 기반 세밀한 역할 분리.
- **IP 차단** — 공인 IP 단위 차단의 한계(NAT 공유 사용자 영향). 계정 잠금·MFA·레이트리밋 등 앱 레벨 대응 병행 필요.
- **자동 차단 TTL** — 차단 IP 자동 해제 로직 및 WAF 사용자 지정 규칙 일치값 개수 제한 점검.
- **비밀·상태 관리** — Key Vault·Storage의 Private Endpoint 전면 전환, WORM 장기 보존, Terraform Remote State.
- **가시성** — Sentinel Workbook으로 규칙별 추이·Egress 차단·인시던트 대응 현황 통합 모니터링.

---

*본 프로젝트는 학습 목적으로 구축한 환경을 기준으로 작성되었습니다.*
