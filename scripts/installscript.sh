#!/bin/bash
#Update packages and own opt
sudo yum update -y
sudo chown ec2-user:ec2-user -R /opt

#Install java; corretto has compatibility issues with mvn; use openjdk
sudo amazon-linux-extras install java-openjdk11 -y

#Install maven to compile the java code
#Go here to pick the latest maven version https://maven.apache.org/download.cgi
MVN_VERSION='3.9.4'
wget https://dlcdn.apache.org/maven/maven-3/$MVN_VERSION/binaries/apache-maven-$MVN_VERSION-bin.tar.gz -O apache-maven.tar.gz
tar xvf apache-maven.tar.gz -C /opt
sudo ln -s /opt/apache-maven-$MVN_VERSION /opt/maven

#To access the mvn command systemwide, you need to either set the M2_HOME environment variable or add /opt/maven to the system PATH
echo 'M2_HOME=/opt/maven' | sudo tee -a /etc/profile.d/maven.sh
echo 'export PATH=${M2_HOME}/bin:${PATH}' | sudo tee -a /etc/profile.d/maven.sh
sudo chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh
#mvn -version

#Install docker
sudo amazon-linux-extras install docker -y
sudo service docker start
#sudo docker -v

#Get the source code and unzip in opt and build the WAR
mkdir /opt/HelloWorld && cd $_
wget https://d6opu47qoi4ee.cloudfront.net/labs/tio/devops/HelloWorld.zip
unzip HelloWorld.zip
rm HelloWorld.zip
mvn package
