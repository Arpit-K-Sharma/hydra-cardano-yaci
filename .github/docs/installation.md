# Installation Guide

## Supported Systems

- Ubuntu/Debian 20.04+
- macOS 11+ (Apple Silicon/Intel)
- Windows 10/11 (*via WSL2*)

## Tools You Need

- [Node.js](https://nodejs.org/) >= 20.8 (npm included)
- Docker
- curl, git, unzip
- Yaci DevKit (see main docs/Yaci repo)

---

### Linux/WSL2 Quickstart

```sh
sudo apt update
sudo apt install -y curl git unzip
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```
Log out/log in after Docker install.

---

### Yaci DevKit setup

```sh
bash scripts/devnet/install-yaci-devkit.sh
```
Or

npm run setup:devkit

(And follow [Yaci DevKit docs](https://devkit.yaci.xyz/introduction) for custom workflows.)

---

### Check Everything

```sh
npm run install:prerequisites
```
(Verifies node, npm, Docker, Yaci presence, outputs diagnostics.)

---

- For macOS use [Homebrew](https://brew.sh/) for all packages and install Docker Desktop.
- For Windows (WSL2), follow the Ubuntu steps above *inside* your Linux environment.