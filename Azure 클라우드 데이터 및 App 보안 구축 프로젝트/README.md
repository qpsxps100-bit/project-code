# Azure 클라우드 데이터 및 App 보안 구축

> **기간** 2026.09.09 ~ 2026.09.23 (15일) · **인원** 팀 프로젝트 (6명) · **역할** 팀장 — 총괄 · 아키텍처 설계 · Terraform IaC · Sentinel 탐지/Logic App 자동 차단
> **서비스 도메인** https://team4.ghjo.cloud

인터넷에 공개된 웹 서비스를 대상으로 한 외부 공격(SQL 인젝션·XSS·취약점 스캔·과다 요청·무차별 대입)을 **탐지에서 자동 차단까지** 방어하는 체계를 구축한 프로젝트입니다. Microsoft Azure(Korea Central)에 회원가입·로그인을 제공하는 **3-Tier 웹 서비스(Web·WAS·DB)**를 Hub-Spoke 네트워크 위에 Terraform(IaC)으로 재현 가능하게 구성하고, Microsoft Sentinel과 Logic App을 연계해 확인된 공격 IP를 자동 차단하도록 했습니다.

## 🧱 사용 기술

| 영역 | 기술 |
|---|---|
| 클라우드 / IaC | Microsoft Azure (Korea Central), Terraform ≥ 1.8 (azurerm ~> 4.0) |
| 네트워크 | Hub-Spoke VNet, VNet Peering, NSG, UDR → Azure Firewall egress 강제 |
| 보안 경계 | Application Gateway WAF_v2 (OWASP 3.2 · Prevention), Azure Firewall, Azure Bastion |
| 3-Tier 서비스 | Web(nginx) · WAS(Flask + gunicorn) · DB(MySQL Flexible Server) + Private DNS |
| 비밀 / 인증 | Key Vault(RBAC), Managed Identity(id-appgw · id-mysql + VM 시스템 할당), Entra ID |
| 탐지 / 대응 | Microsoft Sentinel(분석 규칙 7종 + Hunting Query), Log Analytics, DCR + Azure Monitor Agent, Logic App 자동 차단 |

## 🏗️ 아키텍처 개요

- **Hub-Spoke** — Hub VNet(10.10.0.0/16) ↔ Spoke VNet(10.20.0.0/16) 양방향 Peering
- **3-Tier** — App Gateway(WAF) → Web(nginx) → WAS(Flask) → MySQL, 계층별 NSG 격리
- **egress 통제** — Spoke Web·WAS 아웃바운드를 UDR로 Azure Firewall에 강제 경유(FQDN 허용목록)
- **단일 진입점** — App Gateway WAF_v2(OWASP 3.2, Prevention)로 HTTPS 443만 개방, 인증서는 Key Vault 관리 ID로 수신
- **탐지 → 자동 대응** — 로그를 Log Analytics로 통합 → Sentinel 분석 규칙 7종으로 탐지 → Logic App이 공격 IP를 WAF 차단목록(AutoBlockedIP)에 자동 추가

## 🎯 핵심 목표 및 결과

1. **IaC 자동화** — 전체 인프라를 Terraform으로 코드화하여 재현 가능한 배포 체계 구축
2. **네트워크 격리·egress 통제** — Hub-Spoke Peering + UDR로 모든 아웃바운드를 Azure Firewall에 강제 경유, NSG 계층 분리
3. **웹 보안 경계** — App Gateway WAF_v2(OWASP 3.2 Prevention)로 HTTPS 443 단일 진입점, KV 인증서 관리 ID 수신
4. **비밀 내부화 방지** — DB 비밀번호·TLS 인증서·SSH 키를 Key Vault에만 보관, RBAC 역할 분리 + Managed Identity
5. **탐지** — WAF·Firewall·Bastion·MySQL·Syslog 로그를 Log Analytics로 통합, Sentinel 분석 규칙 7종 + Hunting Query로 외부 공격 탐지
6. **자동 대응** — Logic App이 탐지된 공격 IP를 WAF 차단목록에 자동 추가하고 인시던트에 대응 기록(최소 권한)
7. **검증** — Kali Linux Brute Force · 외부 스캐너 공격으로 WAF 즉시 차단, Sentinel 탐지 → 자동 차단 실증

## 🚀 구성 디벨롭 — 내부 행위 기반 탐지·대응 + 데이터 유출 방지

본 프로젝트는 외부 공격의 탐지·자동 차단에 집중했으며, 차기 과제로 남긴 **내부 행위 기반 탐지·대응**과 **데이터 유출 방지(Egress Containment)**를 후속으로 구현·실데이터 검증했습니다. (`17_sqldb` · `21~29_*.tf`)

- **데이터 유출 방지(Egress Containment)** — Storage 공유키 비활성·WORM 불변, MySQL **Entra 토큰 인증·`aad_auth_only`**, App Gateway↔Web 백엔드 TLS(KV 인증서 재사용)로 반출 경로 봉쇄
- **내부 행위 탐지 — 자동 분석 규칙 7종** — 권한·역할 변경, NSG·방화벽 정책 변경, Key Vault 거부 접근, DB 사용자/권한 변경, Storage 대량 반출, 미허용 아웃바운드(Egress Deny), VM 파일 변조(auditd FIM) → 전부 인시던트 생성 검증
- **탐지 2층 구조 — Hunting Query 확장(내부 5종)** — 권한변경→비밀열람 상관, 신규 Egress FQDN, 시크릿 대량 열람, DB 대량 SELECT, 희귀 관리평면 작업
- **대응 계층화(SOAR) — 수동 Playbook 4종** — VM 격리 / 격리 해제 / Storage 긴급 봉쇄 / 증거 보전 스냅샷 (대응 액션별 Logic App 분리 + 최소권한)
- **알림** — High·Medium 인시던트 메일 발송

## 📁 디렉터리

```
01_team4/                 # Terraform 모듈 (Korea Central 단일 스택)
├── 00_init.tf ~ 20_rbac.tf    # 네트워크·보안경계·3-Tier·KV·RBAC
├── 21~22_*.tf                 # 진단 설정 · VM 모니터링(DCR/AMA)
├── 23_sentinel_rules.tf       # 외부 공격 탐지 규칙 7종
├── 24_notification.tf         # 인시던트 메일 경보(High·Medium)
├── 25_autoblock.tf            # Logic App 자동 차단(WAF)
├── 26_hunting.tf              # Hunting Query (외부 4 + 내부 5)
├── 27_activity_diag.tf        # 구독 Activity → LAW
├── 28_sentinel_internal_rules.tf  # 내부 행위 탐지 규칙 7종
├── 29_soar_playbooks.tf       # 수동 대응 Playbook 4종
├── web_cloudinit.yaml / was_cloudinit.yaml
└── terraform.tfvars.example
```

## ⚙️ 배포

```bash
cd 01_team4
cp terraform.tfvars.example terraform.tfvars   # 구독 ID·도메인·Object ID 등 입력
terraform init && terraform plan && terraform apply
```

> 민감정보(SSH 키·인증서·tfstate·tfvars)는 커밋하지 않습니다. `.gitignore` 참조.

## 🔭 향후 고도화

Sentinel Workbook 통합 대시보드 · Entra SignInLogs 기반 비활성 계정 탐지 · 자동 차단 TTL·TI 평판 보강 · Private Endpoint 전면화 · KV Purge Protection · Locked WORM 장기 보존
