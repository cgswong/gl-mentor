#!/bin/bash
#Create the docker image
mkdir /opt/docker && cd $_
cp /opt/HelloWorld/target/HelloWorld-1.war HelloWorld.war   
echo 'FROM tomcat:jre11' >> dockerfile
echo 'run rm -rf /usr/local/tomcat/webapps' >> dockerfile
echo 'run mkdir /usr/local/tomcat/webapps' >> dockerfile
echo 'ADD HelloWorld.war /usr/local/tomcat/webapps/ROOT.war' >> dockerfile
sudo docker build -f dockerfile -t helloworld:v1 .

#Test the image locally. Ensure port 80 is open. Access the app by http://EC2instancepublicIP
sudo docker run -d -p 80:8080 helloworld:v1

EC2_PUB_IP=$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has" | awk '{print $4}')
echo -e '\n\nCopy and paste the link below in a new browser tab to access the application running as a container on this EC2 instance.\nhttp://'$EC2_PUB_IP'/'
