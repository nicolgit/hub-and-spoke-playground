This repo contains an Azure Hub and Spoke topology to use as baseline for networking tests.

# Architecture
this is the architecture

# main components and information on the scenario
lorem ipsut dixit

# how to deploy
via Azure CLI

az provider register --namespace 'Microsoft.Network'


az group create --name hub-and-spoke-playground --location westeurope

az deployment group create --resource-group hub-and-spoke-playground --template-uri https://raw.githubusercontent.com/nicolgit/hub-and-spoke-playground/main/azuredeploy.json


