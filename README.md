# Kubernetes Cluster

Este repositório contem os passos necessários para a criação de um cluster kubernetes.

Separei a inicialização em dois arquivos, um para inicializar o control plane (init_control_plane.sh) e outro para inicializar os workers.

Dentro do arquivo de inicialização do control plane adicionei o comando para instalação de um CNI no caso o weave. Foi adicionado também a instalação do ingress-controller.