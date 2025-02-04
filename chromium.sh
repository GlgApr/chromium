#!/bin/bash
set -e  # Exit script jika ada error

# Deklarasi variabel global
username=""
password=""

# Function untuk validasi input
validate_input() {
  local input=$1
  local field=$2
  if [[ -z "$input" ]]; then
    echo "❌ $field tidak boleh kosong!"
    return 1
  fi
  return 0
}

# Function untuk meminta input username
get_username() {
  while true; do
    read -r -p "Masukkan username (kosongkan untuk generate otomatis): " input_username
    if [[ -z "$input_username" ]]; then
      export username=$(openssl rand -hex 4)
      echo "✅ Menggunakan username acak: $username"
      break
    else
      if validate_input "$input_username" "Username"; then
        export username=$input_username
        echo "✅ Menggunakan username: $username"
        break
      fi
    fi
  done
}

# Function untuk meminta input password
get_password() {
  while true; do
    read -r -p "Masukkan password (kosongkan untuk generate otomatis): " input_password
    if [[ -z "$input_password" ]]; then
      export password=$(openssl rand -base64 12 | tr '+/' '!@')
      echo "✅ Menggunakan password acak: $password"
      break
    else
      if validate_input "$input_password" "Password"; then
        export password=$input_password
        echo "✅ Menggunakan password yang dimasukkan"
        break
      fi
    fi
  done
}

# Cek root access
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ Jalankan script dengan sudo!"
  exit 1
fi

# Install jq untuk timezone detection
if ! command -v jq &> /dev/null; then
  echo "Installing jq..."
  apt install -y jq || yum install -y jq
fi

# Docker installation yang lebih kompatibel
install_docker() {
  echo "🔧 Installing Docker..."
  curl -fsSL https://get.docker.com | bash
  systemctl enable --now docker
}

# Gunakan docker compose V2
install_docker_compose() {
  echo "🔧 Installing Docker Compose..."
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
}

# Main installation
if ! command -v docker &> /dev/null; then
  install_docker
else
  echo "✅ Docker sudah terinstall"
fi

if ! docker compose version &> /dev/null; then
  install_docker_compose
else
  echo "✅ Docker Compose sudah terinstall"
fi

# Port checking
test_port() {
  ss -tuln | grep -q ":$1 "  # Menggunakan ss sebagai pengganti netstat
  return $?
}

if test_port 3010; then
  echo "❌ Port 3010 sedang digunakan!"
  exit 1
fi

if test_port 3011; then
  echo "❌ Port 3011 sedang digunakan!"
  exit 1
fi

# Meminta input username dan password
get_username
get_password

# Timezone detection dengan fallback
timezone=$(curl -s http://ip-api.com/json | jq -r '.timezone // "Europe/London"')

# Setup direktori
config_dir="/opt/chromium-browser"
mkdir -p "$config_dir"

# Docker compose file
cat > "$config_dir/docker-compose.yml" <<EOF
version: '3.8'

services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=$timezone
      - CUSTOM_USER=$username
      - PASSWORD=$password
    volumes:
      - $config_dir:/config
    ports:
      - "3010:3000"  # Web UI
      - "3011:3001"  # Remote debugging
    shm_size: "2gb"
EOF

# Jalankan dengan docker compose V2
cd "$config_dir"
docker compose up -d

# Dapatkan IP dengan multiple sources
get_ip() {
  curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}'
}

IP=$(get_ip)
echo ""
echo "========================================"
echo "🌐 Akses Browser: http://$IP:3010"
echo "🔧 Remote Debug: http://$IP:3011"
echo "🔑 Username: $username"
echo "🔒 Password: $password"
echo "========================================"
