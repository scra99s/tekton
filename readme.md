# Attempting to work out how to use tekton
## Pre-requisites
- Running on Win10 with docker desktop and kubernetes installed, all control through wsl cli.
- It's pretty simple to set all this up. Install wsl, docker-desktop, k8s, tekton, tekton-dashboard...
- If your not sure how all that works here is a somewhat terrible guide.

__Powershell__
```powershell
# Enable wsl.
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Set version to 2.
wsl --set-default-version 2

# Install Ubuntu.
wsl --install -d Ubuntu-20.04

# Set Ubuntu as the default.
wsl --set-default Ubuntu-20.04
```
- You probably have to restart your pc at this point.
- Start up docker desktop and enable kubernetes. Once kubes is up, move on.

__Ubuntu Shell__
```bash
# Install the ingress controller.
kubectl.exe apply --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.41.2/deploy/static/provider/cloud/deploy.yaml

# Install Tekton.
kubectl.exe apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Install Tekton dashboard, for them views!
kubectl.exe apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
```
---
## Secrets
You need to create a .secrets.ini file in the setup/config directory with the following variables.
```bash
#!/usr/bin/bash
declare -A templateVariables
declare workingDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

########################################
# SSH Secrets for git.
##
# Format: base64 encoded ssh private key.
templateVariables[__GIT_SSH_PRIVATE_KEY__]="<ssh private key here>"
##
# Format: base64 encoded repository key.
templateVariables[__GIT_SSH_KNOWN_HOSTS__]="<repository key here>"

########################################
# Basic auth secrets for docker registry.
##
# Format: Clear text username.
templateVariables[__REGISTRY_USERNAME__]="<username here>"
##
# Format: Clear text password.
templateVariables[__REGISTRY_PASSWORD__]="<password here>"

########################################
# SSL secrets
##
# Format: x509 server certificate, generated with secrets/generate.sh
templateVariables[__SSL_SERVER_CERT__]="$workingDir/../secrets/server.crt"
templateVariables[__SSL_SERVER_CERT_B64__]="$(cat $workingDir/../secrets/server.crt | base64 -w 0)"
##
# Format: x509 server key, generated with secrets/generate.sh
templateVariables[__SSL_SERVER_KEY__]="$workingDir/../secrets/server.key"
templateVariables[__SSL_SERVER_KEY_B64__]="$(cat $workingDir/../secrets/server.key | base64 -w 0)"
##
# Format: x509 CA certificate, generated with secrets/generate.sh
templateVariables[__SSL_CA_CERT__]="$workingDir/../secrets/serverCA.crt"
```

## Patch Tekton
As we are using a self signed set of keys for the registry, tekton can't deal. Basically replacing the default CA here.
```bash
# Update the config map for registry auth.
bash setup/config/kubeapply.sh setup/patches/ConfigMap.yaml

# Create SSL secret for the ingress controller.
bash setup/config/kubeapply.sh setup/patches/Secret.yaml

# Create an ingress route for the tekton-dashboard.
# You will need to create dns entry somewhere, I use pi-hole,
# if you need a ghetto fix open notepad as administrator, open
# C:\Windows\System32\drivers\etc\hosts and add the following entry:
# <your ip address> tekton-dashboard.jerra.io
# <your ip address> docker-registry.jerra.io
# <your ip address> web-app.jerra.io
# e.g. 192.168.1.2 tekton-dashboard.jerra.io
bash setup/config/kubeapply.sh setup/patches/Ingress.yaml
```
## Deploy Docker Registry
- We need a local registry to test auth methods.
```bash
# Deploy the registry.
bash setup/config/kubeapply.sh app/registry/registry-deployment.yaml
```

## Deploy Pipeline
```bash
# Create the pipeline namespace and secrets.
bash setup/config/kubeapply.sh pipeline/Secrets.yaml

# Create the pipeline.
kubectl.exe -f apply pipeline/Pipeline.yaml
```
