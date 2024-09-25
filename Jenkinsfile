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
                py.test ./tests/unit/ --verbose --junit-xml test-reports/results.xml
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
                <enter your code here>
                '''
            }
        }
    }
}
