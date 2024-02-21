#!/bin/bash
# !!IMPORTANT!! !!THIS SCRIPT MUST BE RUN WITH 'bash <name>.sh'!!

# install docker and jenkins - add user and jenkins to docker group.

# Check if Docker is already installed by checking the docker command
if ! command -v docker &> /dev/null; then
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
    sudo apt install fontconfig openjdk-17-jre -y
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
    sudo apt-get install jenkins -y 

    sudo usermod -aG docker jenkins
    
else
    echo "Jenkins is already installed."
fi

# Download and install Jenkins plugins: Configuration as Code and Docker Pipeline
echo "Installing Jenkins plugins..."
sudo wget https://updates.jenkins.io/latest/configuration-as-code.hpi -O /var/lib/jenkins/plugins/configuration-as-code.hpi
sudo wget https://updates.jenkins.io/latest/docker-workflow.hpi -O /var/lib/jenkins/plugins/docker-workflow.hpi

# Set correct permissions for plugins
sudo chown jenkins:jenkins /var/lib/jenkins/plugins/*.hpi

# Create Groovy script to disable setup wizard
echo "Disabling Jenkins setup wizard..."
sudo mkdir -p /var/lib/jenkins/init.groovy.d
echo 'import jenkins.model.*; import hudson.util.*; import jenkins.install.*; def instance = Jenkins.getInstance(); instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)' | sudo tee /var/lib/jenkins/init.groovy.d/init-setup-wizard.groovy > /dev/null


# Set correct permissions for init script
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/

# update ip in jenkins.yaml

IP_ADDRESS=$(curl -s ifconfig.me)
# Update the jenkins.yaml file with the new IP address
sed -i "s|http://:8080/|http://${IP_ADDRESS}:8080/|g" jenkins.yaml
sed -i "s|http://:8080/webhook|http://${IP_ADDRESS}/webhook|g" jenkins.yaml

# Place JCasC configuration file
echo "Configuring Jenkins with JCasC..."
sudo cp jenkins.yaml /var/lib/jenkins/jenkins.yaml  # Make sure to update this path to your actual jenkins.yaml file
sudo chown jenkins:jenkins /var/lib/jenkins/jenkins.yaml

# Create a directory for Jenkins service overrides
sudo mkdir -p /etc/systemd/system/jenkins.service.d

# Create an override file for Jenkins service
echo "[Service]
Environment=\"CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml\"" | sudo tee /etc/systemd/system/jenkins.service.d/casc.conf > /dev/null

echo "Disabling Jenkins setup wizard..."
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/java -Djenkins.install.runSetupWizard=false -jar /usr/share/java/jenkins.war|' /lib/systemd/system/jenkins.service

# Disable Jenkins security in the config.xml file
echo "Disabling Jenkins security..."
sudo sed -i 's/<useSecurity>true<\/useSecurity>/<useSecurity>false<\/useSecurity>/' /var/lib/jenkins/config.xml

# Restart Jenkins to apply changes
echo "Restarting Jenkins to load new plugins and configuration..."
sudo systemctl daemon-reload
sudo systemctl restart jenkins
echo "Jenkins setup complete with Configuration as Code and Docker Pipeline plugins installed. Initial setup wizard disabled."

# Print the message with the public IP address
echo "Jenkins setup is complete. Please go to http://${IP_ADDRESS}:8080 in your browser to access Jenkins."