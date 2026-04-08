# Hybrid Cloud — AWS Site-to-Site VPN Lab

> **Status: FULLY OPERATIONAL** — Both IPSec tunnels UP | Ubuntu VM ↔ AWS EC2 private subnet

A production-grade hybrid cloud implementation connecting an **Ubuntu 24.04 VM (VMware Workstation)** to an **AWS VPC** over an encrypted IPSec Site-to-Site VPN using strongSwan. This repo contains the complete step-by-step implementation guide including every issue encountered, root cause analysis, and exact resolution commands.



<img width="1050" height="747" alt="image" src="https://github.com/user-attachments/assets/e60f0cee-2dfa-43d5-b8e8-98cfaf8203a6" />


---

## Architecture

```
 On-Premises (VMware)                        AWS Cloud
┌──────────────────────┐                ┌────────────────────────────┐
│  Ubuntu 24.04 VM     │                │  VPC: 10.0.0.0/16          │
│  192.168.91.145      │                │                            │
│  strongSwan 5.9.13   │◄──IKEv1 ESP───►│  Virtual Private Gateway   │
│  IPSec IKEv1         │  UDP 4500      │                            │
└──────────┬───────────┘                │  ┌─────────────────────┐   │
           │                            │  │ Private Subnet      │   │
    Home Router (NAT)                   │  │ 10.0.1.0/24         │   │
    172.220.62.45                       │  │                     │   │
                                        │  │ EC2 (Amazon Linux)  │   │
                                        │  │ 10.0.1.23           │   │
                                        │  └─────────────────────┘   │
                                        └────────────────────────────┘

  Tunnel 1: 172.220.62.45 <-> 52.55.138.58   (inside: 169.254.46.238/30)
  Tunnel 2: 172.220.62.45 <-> 52.206.45.187  (inside: 169.254.54.154/30)
```

---

## Lab Specs

| Component | Detail |
|---|---|
| On-Prem OS | Ubuntu 24.04 LTS on VMware Workstation (Bridged) |
| VPN Software | strongSwan 5.9.13 — IPSec IKEv1 |
| On-Prem Network | 192.168.91.0/24 |
| Ubuntu VM IP | 192.168.91.145 |
| Public IP (CGW) | 172.220.62.45 |
| AWS VPC | 10.0.0.0/16 |
| AWS VPN ID | vpn-0a9aa2a54ab7106e3 |
| Tunnel 1 AWS EP | 52.55.138.58 |
| Tunnel 2 AWS EP | 52.206.45.187 |
| EC2 Instance | 10.0.1.23 (Amazon Linux 2023, t3.micro) |
| Lab Date | April 7, 2026 |

---

## What's in the Documentation

The included `hybrid_cloud_lab.docx` is a **complete implementation record** covering:

### Phase 1 — AWS Infrastructure
- VPC, subnets (public + 2 private AZs), Internet Gateway, route tables
- Virtual Private Gateway (VGW) + Customer Gateway (CGW) configuration
- Site-to-Site VPN connection with dual tunnels and static routing
- Route propagation + Security Group for ICMP/SSH over VPN

### Phase 2 — Ubuntu VM / strongSwan Setup
- VMware Bridged adapter configuration
- strongSwan installation and IP forwarding tuning
- Complete `/etc/ipsec.conf` (IKEv1, AES-128, SHA-1, modp1024, NAT-T)
- `/etc/ipsec.secrets` pre-shared key setup
- iptables / netfilter-persistent firewall rules (ESP, UDP 500/4500, MASQUERADE)
- Manual VTI interface creation (vti1/vti2) with routing

### Phase 3 — EC2 Instance
- Key pair creation and IAM SSM role
- Private subnet launch (no public IP — VPN access only)

### Issues & Resolutions (8 documented)
All real problems hit during this lab with exact error messages, root cause, and fix:

| # | Issue | Root Cause |
|---|---|---|
| 1 | iptables-persistent removed UFW | Package conflict on Ubuntu 24.04 |
| 2 | `NO_PROPOSAL_CHOSEN` Phase 2 failure | Missing `modp1024` in ESP proposal |
| 3 | `pfs=no` deprecated keyword warning | Removed in strongSwan 5.9.13 |
| 4 | strongswan.conf syntax error | Duplicate `charon {}` block appended |
| 5 | charon.conf corrupted | Bad block prepended via shell redirect error |
| 6 | Stale PID files blocking restart | Killed with `pkill -9`, no cleanup |
| 7 | VTI interfaces not auto-created | updown script not firing in this env |
| 8 | `checkconfig` command not found | Removed in strongSwan 5.9.13 |

---

## Final Verification Results

### Tunnel Status
```
aws-tunnel-1[3]: ESTABLISHED 17 minutes ago, 192.168.91.145[172.220.62.45]...52.55.138.58
aws-tunnel-1{7}: INSTALLED, TUNNEL, ESP in UDP SPIs: c68c1957_i c1585fa2_o
aws-tunnel-1{7}: 192.168.91.0/24 === 10.0.0.0/16

aws-tunnel-2[4]: ESTABLISHED 17 minutes ago, 192.168.91.145[172.220.62.45]...52.206.45.187
aws-tunnel-2{8}: INSTALLED, TUNNEL, ESP in UDP SPIs: c3269caa_i cb7d589a_o
aws-tunnel-2{8}: 192.168.91.0/24 === 10.0.0.0/16
```

### Ping Test (Ubuntu VM to EC2)
```
ping -c 3 10.0.1.23
64 bytes from 10.0.1.23: icmp_seq=1 ttl=127 time=51.4 ms
64 bytes from 10.0.1.23: icmp_seq=2 ttl=127 time=52.2 ms
64 bytes from 10.0.1.23: icmp_seq=3 ttl=127 time=50.4 ms
--- 3 packets transmitted, 3 received, 0% packet loss ---
```

### SSH Test (Private EC2 — VPN-only access, no public IP)
```
ssh -i ~/.ssh/hybrid-keypair.pem ec2-user@10.0.1.23
[ec2-user@ip-10-0-1-23 ~]$ hostname
ip-10-0-1-23.ec2.internal
```

---

## Quick Reference

### Key Commands

| Task | Command |
|---|---|
| Check tunnel status | `sudo ipsec status` |
| Bring up tunnel 1 | `sudo ipsec up aws-tunnel-1` |
| Bring up tunnel 2 | `sudo ipsec up aws-tunnel-2` |
| Restart strongSwan | `sudo systemctl restart strongswan-starter` |
| View live logs | `sudo journalctl -fu strongswan-starter` |
| Check VTI interfaces | `ip addr show vti1 && ip addr show vti2` |
| Check routes to AWS | `ip route show | grep '10.0'` |
| Ping EC2 | `ping -c 4 10.0.1.23` |
| SSH to EC2 | `ssh -i ~/.ssh/hybrid-keypair.pem ec2-user@10.0.1.23` |

### Troubleshooting Quick Lookup

| Error | Cause | Fix |
|---|---|---|
| `NO_PROPOSAL_CHOSEN` | ESP DH group mismatch | `esp=aes128-sha1-modp1024!` |
| `syntax error unexpected end of file` | Unclosed `{` in conf files | Check brace balance |
| `charon.pid exists — skipping` | Stale PID from killed process | `rm -f /var/run/charon.pid` |
| `AUTHENTICATION_FAILED` | PSK mismatch | Check `/etc/ipsec.secrets` |
| Tunnel INSTALLED but ping fails | Security group blocks ICMP | Add ICMP rule from on-prem CIDR |

---

## Completion Checklist

- [x] VPC 10.0.0.0/16 created
- [x] Public and private subnets (3 AZs)
- [x] Virtual Private Gateway attached
- [x] Customer Gateway 172.220.62.45
- [x] VPN Connection with dual tunnels
- [x] Route propagation on private route table
- [x] strongSwan installed and configured
- [x] VTI interfaces vti1 and vti2 created
- [x] Tunnel 1 ESTABLISHED + INSTALLED
- [x] Tunnel 2 ESTABLISHED + INSTALLED
- [x] AWS Console — both tunnels UP
- [x] EC2 in private subnet (no public IP)
- [x] Ping 10.0.1.23 — 0% packet loss
- [x] SSH to EC2 over VPN — Success

---

## Files

| File | Description |
|---|---|
| `hybrid_cloud_lab.docx` | Complete implementation guide with all phases, configs, issues & resolutions |
| `README.md` | This file |

---

*Lab completed: April 7, 2026 | Ubuntu 24.04 + strongSwan 5.9.13 + AWS Site-to-Site VPN*
