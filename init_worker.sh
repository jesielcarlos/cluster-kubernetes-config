#!/bin/bash
# É necessário ter permissão de superusuário no sistema para o script
# funcionar corretamente
#
# Jesiel
# -----------------------------------------------------------------------------

# -- Liberação de portas no iptables
sudo iptables -A INPUT -p tcp --dport 10250 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 30000:32767 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# -- Desabilite o swap de todas as máquinas (Control plane e Workers)
swapoff -a

#
Antes de instalar o Containerd, é preciso habilitar alguns módulos do kernel e configurar os parâmetros do sysctl 
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configuração dos parâmetros do sysctl, fica mantido mesmo com reebot da máquina.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Aplica as definições do sysctl sem reiniciar a máquina
sudo sysctl --system

# -- Para o container runtime, instale o Containerd.

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg --yes
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Configurando o repositório
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt update && sudo apt install containerd.io -y

# -- Crie o seguinte diretório para o containerd e insira suas configurações

sudo mkdir -p /etc/containerd && containerd config default | sudo tee /etc/containerd/config.toml 
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# -- Após isso restart o serviço e verificar seu status

sudo systemctl restart containerd

# -- Agora vamos instalar o Kubeadm, kubelet e kubectl.

sudo apt-get update && \
sudo apt-get install -y apt-transport-https ca-certificates curl

# -- Baixe o Google Cloud public signing key

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# -- Adicione o kubernetes ao repositório do apt

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# -- Atualize e instale o kubelet, kubeadm and kubectl e fixe sua versão

sudo apt-get update
sudo apt-get update && \
sudo apt-get install -y kubelet kubeadm kubectl 

sudo apt-mark hold kubelet kubeadm kubectl 

sudo kubeadm config images pull

sudo systemctl restart containerd kubelet
