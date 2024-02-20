#!/bin/bash

## Install Docker

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o docker-compose
mv docker-compose /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# Set variables
SYSTEM_IP_ADDRESSES=($(hostname -I))
export JENKINS_DOCKER_REGISTRY_IP=${SYSTEM_IP_ADDRESSES[0]}

# Build jenkins docker image
docker-compose build

# Prepare certificates
mkdir certs
sed -i"" "s/subjectAltName=.*/subjectAltName=IP:${SYSTEM_IP_ADDRESSES[0]}/g" openssl.conf
openssl req -newkey rsa:2048 -nodes -keyout certs/registry.key \
	  -x509 -sha256 -days 3650 -subj "/CN=docker-registry" \
	  -out certs/registry.crt -extensions san -config openssl.conf &> /dev/null

docker-compose up -d

cat <<EOL
Jenkins URL: http://${SYSTEM_IP_ADDRESSES[0]}:8080
Gitea URL: http://${SYSTEM_IP_ADDRESSES[0]}:3000
Docker registry URL: https://$JENKINS_DOCKER_REGISTRY_IP

Add this code to your Docker "daemon.json" file:
{
    "insecure-registries": [
        "$JENKINS_DOCKER_REGISTRY_IP:1443"
    ]
}
EOL
