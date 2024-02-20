# jenkins, gitea, docker registry on docker
Jenkins, docker registry and gitea and all collections needed for devops CI/CD are installed in this project. We can implement and test our pipelines, execute ansible projects and have private docker registry by running this project. I could write an one-click script to run all we need manually. But I wanted to show the procedure to make you hands-on with all the component of the project and make you know how it is running :)

# How to run the stack ?

## First we must install docker and docker-compose
``` bash
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

# Install docker and compose plugin
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Download and add docker-compose command
curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o docker-compose
mv docker-compose /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

docker-compose --v version
```

## Set global variables (Get IP of server)
``` bash
SYSTEM_IP_ADDRESSES=($(hostname -I))
export JENKINS_DOCKER_REGISTRY_IP=${SYSTEM_IP_ADDRESSES[0]}
```

## Build jenkins docker image
There is `Dockerfile` on the project. If you open it you see all the plugins of jenkins. In ansible.yml, there are all the collections that are being installed.

``` bash
docker-compose build
```

## Prepare certificates (self-sign)
``` bash
mkdir certs
sed -i"" "s/subjectAltName=.*/subjectAltName=IP:${SYSTEM_IP_ADDRESSES[0]}/g" openssl.conf
openssl req -newkey rsa:2048 -nodes -keyout certs/registry.key \
          -x509 -sha256 -days 3650 -subj "/CN=docker-registry" \
          -out certs/registry.crt -extensions san -config openssl.conf &> /dev/null
```

## Start the Stack
``` bash
docker-compose up -d
```

### Show all endpoint addresses
``` bash 
cat <<EOL
Gitea URL: http://${SYSTEM_IP_ADDRESSES[0]}:3000
Jenkins URL: http://${SYSTEM_IP_ADDRESSES[0]}:8080

Add this code to your Docker "daemon.json" file:
{
    "insecure-registries": [
        "$JENKINS_DOCKER_REGISTRY_IP:1443"
    ]
}
EOL
```
