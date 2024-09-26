#!/bin/bash
#set up the server so that has all of the dependencies that the application needs
sudo apt update && sudo apt install fontconfig openjdk-17-jre software-properties-common && sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.9 python3.9-venv
#clone the GH repository
#git pull https://github.com/kura-labs-org/C5-Deployment-Workload-4.git
if [ ! -d "microblog_VPC_deployment" ]; then
	git clone https://github.com/KZhou1234/microblog_VPC_deployment.git
else
	git pull https://github.com/KZhou1234/microblog_VPC_deployment.git
fi

cd microblog_VPC_deployment

python3.9 -m venv venv
source venv/bin/activate
sudo apt update && sudo apt install python-pip
#install the application dependencies from the requirements.txt file
pip install -r requirements.txt
pip install gunicorn pymysql cryptography
#set ENVIRONMENTAL Variables
export FLASK_APP=microblog.py
#flask commands
flask translate compile
flask db upgrade
#gunicorn command
gunicorn -b :5000 -w 4 microblog:app --daemon
