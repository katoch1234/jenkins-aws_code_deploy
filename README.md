# Automating Deployment of Oriserve Web App in AWS

This repository contains the configuration and scripts for automating the deployment of the Oriserve web application using Jenkins, AWS CodeDeploy, and GitHub.

## Tools Used
- **Jenkins**
- **AWS CodeDeploy**
- **GitHub**

## GitHub Repository
[https://github.com/katoch1234/jenkins-aws_code_deploy.git](https://github.com/katoch1234/jenkins-aws_code_deploy.git)

## Prerequisites

### IAM Roles
1. **CodeDeploy Role**: Create an IAM role for the CodeDeploy service with the required predefined policies.
2. **ASG Role**: Create an IAM role for the Auto Scaling Group (ASG) so that EC2 instances can access CodeDeploy. This role should also include permissions to list S3 buckets: `EC2CodeDeploy`.

## Steps to Automate Deployment

### Step 1: Create Launch Template
- **Name**: `oriserve-app-launch-template`
- **Attach IAM Role**: Use the IAM role created for ASG.
- **User Data for Launch Template**:

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
Note: Remember to add tags to the Launch Configuration.

Step 2: Create Auto Scaling Group
Name: oriserve-app-asg
Launch Template: Use the launch template created in Step 1.
Load Balancer:
Select "Attach a new Load Balancer."
Name: oriserve-app-asg-alb
Target Group Creation: Configure as per application needs.
Scaling Policy:
Enable automatic scaling using the Target Tracking Scaling Policy.
Metric Type: CPU Utilization.
Step 3: Create appspec.yml File
Push the following appspec.yml file to the GitHub repository containing the application source code:

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
Create Application: Name it oriserve-web-app.
Create Deployment Group: For the application created.
Name: oriserve-web-app-dg
Create Deployment: Integrate with Jenkins by setting up GitHub as the source provider.
Repository: <GitHubUsername>/<RepoName>
Additional Deployment Settings: Select "Overwrite."
Step 5: Launch EC2 Instance for Jenkins Server
User Data for Jenkins Server:

bash
Copy code
#!/bin/bash
apt update && apt upgrade -y
# Installing Java
apt install fontconfig openjdk-17-jre wget -y
java -version
# Installing Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install jenkins -y
# Installing AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install unzip -y && unzip awscliv2.zip
./aws/install
Step 6: Install Jenkins Plugins
In Jenkins, go to Manage Jenkins > Manage Plugins and install the following plugins:

AWS CodeDeploy Plugin
GitHub Plugin
Pipeline: AWS Steps Plugin
Step 7: Configure Jenkins
GitHub Credentials:

Go to Manage Jenkins > Credentials and create a GitHub credential using a personal access token.
Create a webhook in the GitHub repository's settings to trigger Jenkins on a push event.
AWS Credentials:

Go to Manage Jenkins > Manage Credentials > (Global).
Add credentials:
Kind: AWS Credentials
Enter your Access Key ID and Secret Access Key.
Provide an ID (e.g., your-aws-credentials) and description.
Step 8: Create Jenkins Pipeline
Create a new Jenkins item (PIPELINE) named Jenkins-codedeploy-pipeline.
Select GitHub project in General.
Select GitHub hook trigger for GITScm polling.
Select Pipeline script from SCM.
Common Issues and Resolutions
Issue: EC2 instances were unable to communicate with CodeDeploy.

Resolution: Restart the CodeDeploy agent after attaching the IAM role to the instance.
Issue: Incorrect file name (appspec.yaml instead of appspec.yml).

Resolution: Rename the file to appspec.yml.
Issue: The IAM role attached to the ASG lacked S3 bucket list and read permissions.

Resolution: Update the IAM role with the necessary S3 permissions.
License
This project is licensed under the MIT License - see the LICENSE file for details.

Contact
For any inquiries or issues, please reach out to Vaibhav Katoch.
