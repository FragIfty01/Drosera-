#!/bin/bash

# === Banner ===
print_banner() {
    echo -e "\e[36m╔════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║              Drosera One Click Setup               ║\e[0m"
    echo -e "\e[36m║        Automate your Drosera Full Installation     ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════╝\e[0m"
}
clear
print_banner

echo "🚀 Drosera Full Auto Install (Docker Mode)"

# === 1. User Inputs ===
read -p "📧 GitHub email: " GHEMAIL
read -p "👤 GitHub username: " GHUSER
read -p "🔐 Drosera private key (0x...): " PK
read -p "🌍 VPS public IP: " VPSIP
read -p "📬 Operator (wallet) public address for whitelist (0x...): " OP_ADDR

for var in GHEMAIL GHUSER PK VPSIP OP_ADDR; do
  if [[ -z "${!var}" ]]; then
    echo "❌ $var is required."
    exit 1
  fi
done

# === 2. Install Dependencies ===
apt-get update && apt-get upgrade -y
apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# === 3. Install Docker ===
apt-get remove docker.io docker-doc docker-compose podman-docker containerd runc -y || true
apt-get update
apt-get install ca-certificates curl gnupg -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update && apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Test Docker
docker run --rm hello-world

# === 4. Install Drosera CLI, Foundry, Bun ===
curl -L https://app.drosera.io/install | bash
source ~/.bashrc
droseraup

curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup

curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

# === 5. Clean Old Directories ===
rm -rf ~/my-drosera-trap

# === 6. Set Up Trap ===
mkdir -p ~/my-drosera-trap && cd ~/my-drosera-trap
git config --global user.email "$GHEMAIL"
git config --global user.name "$GHUSER"
forge init -t drosera-network/trap-foundry-template
bun install
forge build

# === 7. Write drosera.toml ===
cat > drosera.toml <<EOF
ethereum_rpc = "https://ethereum-hoodi-rpc.publicnode.com"
drosera_rpc = "https://relay.hoodi.drosera.io"
eth_chain_id = 560048
drosera_address = "0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D"

[traps]

[traps.helloworld]
path = "out/HelloWorldTrap.sol/HelloWorldTrap.json"
response_contract = "0x183D78491555cb69B68d2354F7373cc2632508C7"
response_function = "helloworld(string)"
cooldown_period_blocks = 33
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size = 10
private_trap = true
whitelist = ["$OP_ADDR"]
EOF

# === 8. Deploy Trap ===
echo "🚀 Deploying trap to Hoodi..."
LOG_FILE="/tmp/drosera_deploy.log"
DROSERA_PRIVATE_KEY=$PK drosera apply | tee "$LOG_FILE"

TRAP_ADDR=$(grep -Eo 'address = "0x[a-fA-F0-9]{40}"' "$LOG_FILE" | head -n1 | cut -d'"' -f2)
if [[ -z "$TRAP_ADDR" ]]; then
  # Try alternative grep
  TRAP_ADDR=$(grep -Eo '0x[a-fA-F0-9]{40}' "$LOG_FILE" | head -n1)
fi

if [[ -z "$TRAP_ADDR" ]]; then
  echo "❌ Failed to detect trap address."
  exit 1
fi

echo "🪤 Trap deployed at: $TRAP_ADDR"

# === 9. Update drosera.toml with trap address ===
echo "address = \"$TRAP_ADDR\"" >> drosera.toml

# === 10. Reapply Trap Config (with address) ===
echo "♻️  Re-applying drosera trap config..."
DROSERA_PRIVATE_KEY=$PK drosera apply | tee "$LOG_FILE"

# === 11. Docker Compose YAML & .env Setup ===
cd ~
mkdir -p ~/Drosera-Network && cd ~/Drosera-Network

cat > docker-compose.yaml <<EOF
version: '3.8'
services:
  drosera-operator:
    image: ghcr.io/drosera-network/drosera-operator:latest
    container_name: drosera-operator
    ports:
      - "31313:31313"
      - "31314:31314"
    environment:
      - DRO__DB_FILE_PATH=/data/drosera.db
      - DRO__DROSERA_ADDRESS=0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D
      - DRO__LISTEN_ADDRESS=0.0.0.0
      - DRO__DISABLE_DNR_CONFIRMATION=true
      - DRO__ETH__CHAIN_ID=560048
      - DRO__ETH__RPC_URL=https://ethereum-hoodi-rpc.publicnode.com
      - DRO__ETH__BACKUP_RPC_URL=https://rpc.hoodi.ethpandaops.io
      - DRO__ETH__PRIVATE_KEY=\${ETH_PRIVATE_KEY}
      - DRO__NETWORK__P2P_PORT=31313
      - DRO__NETWORK__EXTERNAL_P2P_ADDRESS=\${VPS_IP}
      - DRO__SERVER__PORT=31314
      - RUST_LOG=info,drosera_operator=debug
      - DRO__ETH__RPC_TIMEOUT=30s
      - DRO__ETH__RETRY_COUNT=5
    volumes:
      - drosera_data:/data
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:31314/health"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 30s
    command: node
volumes:
  drosera_data:
EOF

cat > .env <<EOF
ETH_PRIVATE_KEY=$PK
VPS_IP=$VPSIP
EOF

# === 12. Start Operator with Docker Compose ===
docker pull ghcr.io/drosera-network/drosera-operator:latest
docker compose down -v || true
docker stop drosera-operator || true
docker rm drosera-operator || true
docker compose up -d

# === 13. Register Operator ===
docker exec drosera-operator drosera-operator register \
  --eth-rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --eth-private-key $PK \
  --drosera-address 0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D

# === 14. Opt-in Operator to Trap ===
docker exec drosera-operator drosera-operator optin \
  --eth-rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --eth-private-key $PK \
  --trap-config-address $TRAP_ADDR

# === 15. Firewall Setup ===
ufw allow ssh
ufw allow 22
ufw allow 31313/tcp
ufw allow 31314/tcp
ufw --force enable

# === 16. Done ===
echo ""
echo "✅ Setup complete."
echo "🪤 Trap: https://app.drosera.io/trap?trapId=$(echo $TRAP_ADDR | tr '[:upper:]' '[:lower:]')"
echo "📖 Docker logs: docker compose logs -f"
