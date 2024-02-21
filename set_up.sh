#!/bin/bash

# install docker and jenkins - add user and jenkins to docker group.

# Check if Docker is already installed by checking the docker command
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing Docker..."
    
    # Download and run the Docker installation script
    curl https://get.docker.com | sudo bash

    # Add your user to the docker group to run docker commands without sudo
    sudo usermod -aG docker $USER

    echo "Docker installation is complete."
else
    echo "Docker is already installed."
fi

# Check for OpenJDK installation
if ! java -version 2>&1 | grep -q 'openjdk version'; then
    echo "OpenJDK is not installed. Installing OpenJDK..."
    sudo apt update
    sudo apt install fontconfig openjdk-17-jre
else
    echo "OpenJDK is already installed."
fi

if ! which jenkins > /dev/null; then
    echo "Jenkins is not installed. Installing Jenkins..."
    
    # Install jenkins
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins

    sudo usermod -aG docker jenkins
    
else
    echo "Jenkins is already installed."
fi

