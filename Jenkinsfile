pipeline {
  agent any
    stages {
        stage ('Build') {
            steps {
		sh '''#!/bin/bash
                python3.9 -m venv venv
                source venv/bin/activate
                pip install -r requirements.txt
                pip install gunicorn pymysql cryptography
                FLASK_APP=microblog.py
                flask translate compile
                flask db upgrade
                '''
            }
        }
        stage ('Test') {
            steps {
		sh '''#!/bin/bash
		sudo apt install python3-pytest
                source venv/bin/activate
                export PYTHONPATH=$(pwd)
			pytest --verbose --junit-xml test-reports/results.xml
                '''
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
      stage ('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
      stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
		setup_path="/home/ubuntu/setup.sh"
		setup_url="https://raw.githubusercontent.com/KZhou1234/microblog_VPC_deployment/refs/heads/main/scripts/setup.sh"
		ssh -i ~/.ssh/id_rsa ubuntu@10.0.1.84 "curl -L -o $setup_path $setup_url 2>/dev/null && chmod 755 $setup_path && source $setup_path"
		
                '''
            }
        }
    }
}
