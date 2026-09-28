# Azure 하이브리드 멀티리전 클라우드 인프라 구축

> **기간** 2026.08.14 ~ 2026.09.02 · **인원** 팀 프로젝트 (4명) · **역할** 팀장 — 총괄 · 아키텍처 설계 · Terraform 모듈화 · MySQL 복제/자동 전환

단일 서버·단일 리전 의존 구조의 장애 위험을 해소하기 위해 **고가용성 · 재해복구(DR) · 보안**을 갖춘 하이브리드 멀티리전 클라우드 인프라를 구축한 프로젝트입니다. Azure 2개 리전(Korea Central · Japan East)을 Terraform으로 자동화하고, 온프레미스 환경과 Site-to-Site VPN으로 연동했습니다.

## 🧱 사용 기술

| 영역 | 기술 |
|---|---|
| 클라우드 / IaC | Microsoft Azure (Korea Central · Japan East), Terraform |
| 네트워크 | Hub-Spoke VNet, VNet Peering, Site-to-Site VPN(IPsec), Traffic Manager |
| 컴퓨트 / 가용성 | VMSS + Autoscale, Application Gateway, Internal Load Balancer |
| 데이터 | Azure MySQL Flexible Server, Managed Redis(Private Endpoint), Private DNS |
| 보안 | WAF(OWASP 3.2), Azure Firewall, NSG, Azure Bastion |
| 운영 / 로그 | Log Analytics, ELK(Filebeat · Logstash), 통합 운영 대시보드 |
| 온프레미스 | VLAN/ACL/NAT, L3 스위치 Inter-VLAN Routing |

## 🏗️ 아키텍처 개요

- **Hub-Spoke 멀티리전** — Korea Central(Priority 1) / Japan East(Priority 2)
- **3-Tier** — Web VMSS → WAS VMSS(Internal LB) → MySQL, Redis 세션/캐시
- **하이브리드 연계** — 온프레미스 MySQL 우선 연결, 장애 시 Azure MySQL Fallback/Replication
- **DR** — Traffic Manager 우선순위 기반 Korea → Japan Failover
- **보안 경계** — Application Gateway WAF, Azure Firewall, NSG, Bastion 전용 관리 경로
- **관측** — Log Analytics / Diagnostic Settings + ELK + 실시간 운영 대시보드

## 📁 디렉터리 구조

```
.
├── 01_azure/                 # 재사용 인프라 모듈 (Hub-Spoke, 3-Tier, 보안, VPN, DR, 로그)
│   ├── 00_init.tf ~ 22_log.tf
│   ├── web_vmss.sh / was_vmss.sh   # 부팅 자동 배포 스크립트
│   └── id_rsa.pub                  # VMSS 공개키 (개인키는 미포함)
├── 02_korea/                 # Korea Central 리전 모듈 호출
│   ├── 00_init.tf
│   └── 100_krdata.tf.example  # ← 복사해서 100_krdata.tf 로 값 채워 사용
└── 03_japan/                 # Japan East 리전 모듈 호출
    ├── 00_init.tf
    └── 100_jpdata.tf.example
```

## 🚀 사용 방법

```bash
# 1) 리전별 설정 파일 준비 (비밀값 채우기)
cp 02_korea/100_krdata.tf.example 02_korea/100_krdata.tf
cp 03_japan/100_jpdata.tf.example 03_japan/100_jpdata.tf
#   REPLACE_WITH_... 부분(구독 ID, GitHub PAT, VPN 공유키, DB 비밀번호 등)을 실제 값으로 수정

# 2) SSH 키페어 생성 (개인키는 커밋 금지)
ssh-keygen -t rsa -b 4096 -f 01_azure/id_rsa

# 3) 배포 (리전 디렉터리에서)
cd 02_korea
terraform init
terraform plan
terraform apply
```

## 🔐 보안 관리 기준

- 실제 비밀값이 담기는 `100_krdata.tf`, `100_jpdata.tf`, `*.tfvars`, `terraform.tfstate`, 개인키(`id_rsa`)는 **`.gitignore`로 커밋에서 제외**합니다.
- 저장소에는 값이 비워진 `*.example` 파일만 포함됩니다.

## 🔭 향후 개선 방향

인프라 · 네트워크 · 보안 경계 구축에 집중했으며, **M365 Defender(Defender for Cloud) 기반 위협 탐지 · 보안 모니터링은 실습 환경의 제약으로 이번 범위에서는 구현하지 못했습니다.** 이는 향후 CI/CD 파이프라인, Key Vault, Terraform Remote State 관리 등과 함께 운영 고도화 단계에서 추가로 구현할 계획입니다.

---

*본 프로젝트는 학습 목적으로 구축한 환경을 기준으로 작성되었습니다.*
