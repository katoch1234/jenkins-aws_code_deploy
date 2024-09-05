# Oriserve Web App Deployment Automation

This project automates the deployment of the Oriserve web app in AWS using Jenkins, AWS CodeDeploy, and GitHub. The application is automatically deployed to EC2 instances using CodeDeploy whenever a push event occurs in the GitHub repository.

## Prerequisites

1. **Create IAM Roles**:
   - **CodeDeploy Role**: Create an IAM role for CodeDeploy with the required policies. Attach it to the CodeDeploy service.
   - **ASG Role**: Create an IAM role for the Auto Scaling Group (ASG) so EC2 instances can access CodeDeploy. This role should include S3 permissions for listing and reading buckets.

## Steps to Automate Deployment

### Step 1: Create a Launch Template

- **Name**: `oriserve-app-launch-template`
- **Attach IAM Role**: Use the ASG role created in the prerequisites.
  
**User Data for Launch Template**:

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
Note: Add appropriate tags to the launch configuration for easier identification and management.

Step 2: Create an Auto Scaling Group (ASG)
Name: oriserve-app-asg
Launch Template: Use the launch template created in Step 1.
Load Balancer: Attach a new load balancer:
Name: oriserve-app-asg-alb
Target Group: Configure according to application needs.
Scaling Policy: Enable automatic scaling with the Target Tracking Scaling Policy using CPU utilization as the metric.
Step 3: Create the appspec.yml File
Add the following appspec.yml file to the root of your GitHub repository containing the app's source code:

yaml
Copy code
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

file_exists_behavior: OVERWRITE

branch_config:
    wip\/.*: ~
    main:
        deploymentGroupName: oriserve-web-app-dg
        deploymentGroupConfig:
            serviceRoleArn: arn:aws:iam::011528265029:role/codeDeploy-role
Step 4: Set Up AWS CodeDeploy
Create Application: oriserve-web-app
Create Deployment Group:
Name: oriserve-web-app-dg
Set up Jenkins integration with GitHub as the source provider.
Repository: <GitHubUsername>/<RepoName>
Select Overwrite in additional deployment settings.
Step 5: Launch EC2 Instance for Jenkins Server
Use the following user data to set up Jenkins on an EC2 instance:

bash
Copy code
#!/bin/bash
apt update && apt upgrade -y
apt install fontconfig openjdk-17-jre wget -y
wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt update
apt install jenkins -y
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install unzip -y && unzip awscliv2.zip
./aws/install
Step 6: Install Jenkins Plugins
Go to Manage Jenkins > Manage Plugins and install the following plugins:

AWS CodeDeploy Plugin
GitHub Plugin
Pipeline: AWS Steps Plugin
Step 7: Configure Jenkins
GitHub Credentials:

Go to Manage Jenkins > Credentials and create a GitHub credential using a personal access token.
In the GitHub repository settings, create a webhook to trigger Jenkins on push events.
AWS Credentials:

Go to Manage Jenkins > Manage Credentials > Global and add AWS credentials.
Provide your Access Key ID and Secret Access Key.

Step 8: Create Jenkins Pipeline
Create a new Jenkins Pipeline item named Jenkins-codedeploy-pipeline.
In General, select GitHub project and provide the repository URL.
Check the GitHub hook trigger for GITScm polling option.
Under Pipeline, select Pipeline script from SCM and point to the repository containing the pipeline definition.
Common Issues and Resolutions
Issue: EC2 instances can't communicate with CodeDeploy.

Resolution: Restart the CodeDeploy agent after attaching the IAM role to the instance.
Issue: Incorrect file name (appspec.yaml instead of appspec.yml).

Resolution: Rename the file to appspec.yml.
Issue: ASG IAM role lacks S3 permissions.

Resolution: Update the IAM role to include S3 list and read permissions.
