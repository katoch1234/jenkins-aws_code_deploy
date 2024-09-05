# Oriserve Web App Deployment Automation

This document outlines the steps I took to set up an automated deployment pipeline for the Oriserve web application using Jenkins, AWS CodeDeploy, and GitHub. The pipeline triggers deployments automatically when changes are pushed to the GitHub repository, using AWS CodeDeploy to deploy the application to EC2 instances in an Auto Scaling Group (ASG).

## Tools & Technologies Used
- **Jenkins**: For continuous integration and continuous deployment (CI/CD).
- **AWS CodeDeploy**: To handle deployment of the web application on EC2 instances.
- **GitHub**: To host the application code and trigger the pipeline.
- **AWS Auto Scaling Group (ASG)**: For scalable infrastructure, automatically launching new instances with the latest code.
- **Nginx**: For web server setup.

---

## Steps I Took

### 1. **Setting Up AWS Resources**

#### a. Launch Template
- Created an **EC2 Launch Template** for the Auto Scaling Group (ASG) that installs all necessary packages (Node.js, Nginx, CodeDeploy agent) when a new instance is launched.
- **User Data** script for the Launch Template:
    ```bash
    #!/bin/bash
    apt update
    apt upgrade -y
    apt install nodejs -y
    apt install npm -y
    apt install ruby-full wget -y
    cd /home/ubuntu/
    wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    systemctl status codedeploy-agent
    systemctl start codedeploy-agent
    systemctl enable codedeploy-agent
    apt install nginx -y
    systemctl start nginx
    rm /var/www/html/index.nginx-debian.html
    rm /etc/nginx/sites-available/default
    rm /etc/nginx/sites-enabled/default
    systemctl enable nginx
    ```

#### b. Auto Scaling Group (ASG)
- Created an **Auto Scaling Group** (ASG) that automatically launches EC2 instances using the above Launch Template.
- Configured scaling policies based on CPU utilization to handle load efficiently.
- Attached an Application Load Balancer (ALB) to the ASG for better traffic distribution.

### 2. **Configuring AWS CodeDeploy**
- Set up AWS CodeDeploy for automating the deployment to EC2 instances.
- **Application Name**: `oriserve-web-app`
- **Deployment Group Name**: `oriserve-web-app-dg`
    - Configured to work with the ASG and handle deployments for newly launched EC2 instances.

#### `appspec.yml` File
- Created an `appspec.yml` file that defines how CodeDeploy handles the deployment, specifying where the application files should be copied and what scripts to run.
    ```yaml
    version: 0.0
    os: linux
    files:
      - source: nginx-proxy-config/
        destination: /etc/nginx/conf.d/
        overwrite: true
      - source: app-code/
        destination: /var/www/html/
        overwrite: true

    hooks:
      AfterInstall:
        - location: app-code/scripts/start_server.sh
          timeout: 300
          runas: root
    ```

### 3. **Jenkins Setup**

#### a. Installing Jenkins
- Set up a Jenkins server on a dedicated EC2 instance. 
- Installed required dependencies using the following user data during instance creation:
    ```bash
    #!/bin/bash
    apt update && apt upgrade -y
    apt install fontconfig openjdk-17-jre wget -y
    wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update
    apt-get install jenkins -y
    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    apt install unzip -y && unzip awscliv2.zip
    ./aws/install
    ```

#### b. Plugins Installed in Jenkins
- Installed the following Jenkins plugins:
    - **AWS CodeDeploy Plugin**
    - **GitHub Plugin**
    - **Pipeline: AWS Steps Plugin**

#### c. Jenkins Pipeline Configuration
- Configured Jenkins to pull the application code from GitHub and trigger the deployment on every code push.
- **Jenkinsfile**:
    ```groovy
    pipeline {
        agent any
        environment {
            AWS_DEFAULT_REGION = 'us-east-1'
            S3_BUCKET = 'your-s3-bucket-name'
            CODEDEPLOY_APP = 'oriserve-web-app'
            CODEDEPLOY_GROUP = 'oriserve-web-app-dg'
        }
        stages {
            stage('Checkout Code') {
                steps {
                    git 'https://github.com/katoch1234/jenkins-aws_code_deploy.git'
                }
            }
            stage('Deploy to AWS CodeDeploy') {
                steps {
                    script {
                        withAWS(credentials: 'your-aws-credentials', region: "${AWS_DEFAULT_REGION}") {
                            def s3Prefix = "deployments/${env.BUILD_NUMBER}"
                            s3Upload(bucket: "${S3_BUCKET}", includePathPattern: '**/*', workingDir: '.', path: "${s3Prefix}")
                            awsCodeDeploy(deploymentGroup: "${CODEDEPLOY_GROUP}", applicationName: "${CODEDEPLOY_APP}", s3Location: "${S3_BUCKET}/${s3Prefix}", waitForCompletion: true)
                        }
                    }
                }
            }
        }
    }
    ```

### 4. **GitHub Repository**
- Added the Oriserve web app code to a GitHub repository: [jenkins-aws_code_deploy](https://github.com/katoch1234/jenkins-aws_code_deploy.git).
- Set up a webhook in GitHub to trigger the Jenkins pipeline on every code push to the repository.

### 5. **Deployment Process**

- When code is pushed to the GitHub repository, Jenkins triggers the pipeline.
- The code is uploaded to an S3 bucket.
- AWS CodeDeploy retrieves the code and deploys it to the EC2 instances in the ASG.
- The application files are copied, Nginx is configured, and the web server starts serving the app.

---

## Key Challenges Solved

1. **Scaling Infrastructure**:
   - Integrated Auto Scaling to handle variable load and ensure that new EC2 instances automatically have the latest code deployed.

2. **Automated Deployment**:
   - Configured Jenkins and AWS CodeDeploy to work together seamlessly, enabling fully automated deployments from GitHub to AWS EC2 instances.

3. **Reliable Configuration**:
   - Set up the necessary permissions and IAM roles for AWS services to securely communicate and perform the required actions during deployment.

---

## Future Improvements

- Add monitoring and alerting using AWS CloudWatch to track instance health, CodeDeploy deployments, and overall application performance.
- Set up automated rollback mechanisms in case of deployment failures.
- Optimize the Nginx and Node.js configurations for better performance and security.

---

## Conclusion

This project successfully automates the deployment of the Oriserve web app using a combination of Jenkins, AWS CodeDeploy, and GitHub. The setup ensures that the application is always up-to-date and can handle scaling needs dynamically.
