# 🚀 One Click Drosera Trap & Operator Install (Docker)

![Image](https://github.com/user-attachments/assets/0458cd13-e731-45b6-a18f-9abf7b51bdf3)

---

Automate the setup and background running of your **Drosera Trap** and **Operator** on Ubuntu 24.04+ with a single script.  
No manual editing, no confusion—just run, answer prompts, and you’re live on the Hoodi Testnet.

---

## 🖥️ System Requirements

| Requirement     | Recommended Specs         |
|-----------------|--------------------------|
| **RAM**         | 4 GB                     |
| **CPU CORES**   | 2                        |
| **DISK**        | 10 GB NVMe (recommended) |

---

## 🌐 Recommended VPS Provider

**Contabo VPS**  
👉 [https://contabo.com/en/vps/](https://contabo.com/en/vps/)

- Rent VPS10 ($4.95/month)
- Choose Ubuntu 24.04 (64-bit)
- Save your server password safely
- Connect using `ssh root@ip`

```bash
ssh root@your_vps_ip
```

---

## ⛽ Hoodi Testnet ETH (Hoodi Token)

To interact or mine on the Hoodi Testnet, you’ll need some test ETH.

**Faucet Links:**

- 🔨 Mining Faucet:  
  [https://hoodi-faucet.pk910.de](https://hoodi-faucet.pk910.de)

- 💧 QuickNode Faucet:  
  [https://faucet.quicknode.com/ethereum/hoodi](https://faucet.quicknode.com/ethereum/hoodi)

- 💧 Stakely Faucet:  
  [https://faucets.stakely.io/en/eth-hoodi-testnet](https://faucets.stakely.io/en/eth-hoodi-testnet)

---

## 📦 What Does This Script Do?

This one-click installer:

1. Installs dependencies and Docker
2. Installs Drosera CLI, Foundry, and Bun
3. Initializes a Drosera trap project
4. Deploys and configures your trap
5. Generates `drosera.toml` with whitelist + trap config
6. Sets up your Drosera Operator via Docker
7. Registers and opts-in the operator
8. Optionally boosts your trap with Hoodi ETH
9. Sets up a firewall for required ports
10. Starts everything in the background — ready to go

---

## ⚡️ Installation

Run the following in your VPS:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

You’ll be prompted for:

- GitHub email
- GitHub username
- Drosera private key
- VPS IP address
- Operator public wallet address
- Option to Bloom Boost (yes/no)
  - If yes, you'll enter the ETH amount

---

## 🌸 Bloom Boost (Optional Priority Boost)

You can boost your trap’s on-chain response speed by depositing Hoodi ETH.  
During installation, you'll be asked:

> Do you want to Bloom Boost your trap now?

If yes, the script will run:

```bash
drosera bloomboost --trap-address <trap_address> --eth-amount <amount>
```

You can skip this and boost later from the CLI or [Drosera Dashboard](https://app.drosera.io).

---

## 🔐 Security & Firewall Setup

Firewall ports opened:

- `22` for SSH
- `31313/tcp` for Drosera P2P
- `31314/tcp` for Drosera API

UFW is enabled automatically after installation.

---

## 🟢 After Install

- View logs:  
  ```bash
  docker compose logs -f
  ```

- View your trap dashboard:  
  ```
  https://app.drosera.io/trap?trapId=<your_trap_address>
  ```

- Restart operator:  
  ```bash
  cd ~/Drosera-Network && docker compose restart
  ```

---

## ❓ FAQ / Troubleshooting

**Q: My trap isn’t showing up on the dashboard!**  
A: Wait 1–2 minutes after setup, refresh, and confirm you used the right address.

**Q: How do I update or re-apply my trap config?**  
A: Run in your trap folder:
```bash
cd ~/my-drosera-trap
DROSERA_PRIVATE_KEY=yourkeyhere drosera apply
```

**Q: How do I boost my trap again?**  
A: Run:
```bash
drosera bloomboost --trap-address <trap_address> --eth-amount <amount>
```

---

## 🛡️ Your Keys Stay Local

**You NEVER send private keys anywhere outside your own VPS.**  
This script only uses them to generate configs and CLI commands locally.

---

## 🙋 Need Help?

- Drosera Docs: [https://docs.drosera.io/](https://docs.drosera.io/)
- Official Support: [Discord](https://discord.gg/drosera)

---

**Enjoy automated ZK security and contract monitoring—set up in minutes!**
