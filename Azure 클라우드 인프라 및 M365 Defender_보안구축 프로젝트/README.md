# Azure 하이브리드 멀티리전 클라우드 인프라 구축

> **기간** 2026.08.14 ~ 2026.09.02 · **인원** 팀 프로젝트 (4명) · **역할** 팀장 — 총괄 · 아키텍처 설계 · Terraform 모듈화 · MySQL 복제/자동 전환

단일 서버·단일 리전 의존 구조의 장애 위험을 해소하기 위해 **고가용성 · 재해복구(DR) · 보안**을 갖춘 하이브리드 멀티리전 클라우드 인프라를 구축한 프로젝트입니다. Azure 2개 리전(Korea Central · Japan East)을 Terraform으로 자동화하고, 온프레미스 환경과 Site-to-Site VPN으로 연동했습니다.

## 📌 두 프로젝트, 하나의 코드

이 저장소의 코드는 아래 **두 팀 프로젝트가 공유하는 동일한 Azure 인프라 코드**입니다. 두 프로젝트의 Terraform 코드(`.tf`)는 **100% 동일**하며, 차이는 코드 바깥 구성(온프레미스 물리 장비·ELK, M365 Defender 보안운영)과 보고서의 강조점에 있습니다. 중복을 피하기 위해 Azure 인프라 코드는 이 한 곳에서 관리합니다.

| 프로젝트 | 공통 기반 | 각 프로젝트가 더한 것 |
|---|---|---|
| **Azure 클라우드 인프라 및 M365 Defender 보안구축** | ← 동일한 Azure 멀티리전 Terraform 코드 | M365 Defender(엔드포인트·메일·Alert) 보안운영 관점 |
| **하이브리드 멀티리전 클라우드 보안구축** | ← 동일한 Azure 멀티리전 Terraform 코드 | 온프레미스(Cisco·BLUEMAX·ELK) 연계 · S2S VPN · DR/DB Fallback · 통합 로그 |

> **하이브리드 프로젝트가 추가한 것** (물리 장비·OS 설정이라 Terraform 코드 외부)
> - 온프레미스 물리망 — Cisco Catalyst 3550(L3)·2960, PIOLINK TiFRONT, BLUEMAX NGF100(방화벽)
> - VLAN 분리 — 직원 VLAN100 / 관리자 VLAN200 / DB VLAN250, L3 Inter-VLAN Routing · ACL · NAT/PAT
> - On-Prem MySQL(Primary)·ELK 중앙 로그 수집
> - S2S VPN으로 Azure Web/WAS ↔ 온프레 MySQL(3306)·ELK(5044) 사설 연계
> - On-Prem DB 장애 시 Azure MySQL로 Fallback/Replication 전환·원복

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
