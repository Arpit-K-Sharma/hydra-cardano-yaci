---
title: Installation
layout: page
---

# Installation

## Prerequisites
- Linux (recommended)
- Node.js >= 20.8.0
- Docker (for Docker workflow)
- curl, unzip, git

## Install on Ubuntu/Debian
```sh
sudo apt update
sudo apt install -y curl unzip git
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```
Log out and back in after adding yourself to the docker group.

## Clone the Repository
```sh
git clone https://github.com/your-username/hydra-cardano-yaci.git
cd hydra-cardano-yaci
```

## Install Project Prerequisites
```sh
npm run install:prerequisites
```
