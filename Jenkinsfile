pipeline {
    agent any
    stages{
        stage("clean workspace") {
            steps{
                cleanWs()
            }
        }
        
        stage('Checkout from Git') {
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/katoch1234/jenkins-aws_code_deploy.git'
            }
        }

        stage('Deploy to Code-Deploy') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                sh 'aws deploy create-deployment --application-name oriserve-web-app --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name oriserve-web-app-dg --description "My GitHub deployment demo" --github-location repository=katoch1234/jenkins-aws_code_deploy,commitId=GIT_COMMIT'
            }
        }

    }
}
}
