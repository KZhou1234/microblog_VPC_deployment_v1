#/bin/bash
#ssh into applicaiton server
start_app_url="https://raw.githubusercontent.com/KZhou1234/microblog_VPC_deployment/refs/heads/main/scripts/start_app.sh"
start_app_path="/home/ubuntu/start_app.sh"
ssh -i app_key.pem ubuntu@10.0.2.98 "curl -L -o $start_app_path $start_app_url 2>/dev/null && chmod 755 $start_app_path && source $start_app_path"
