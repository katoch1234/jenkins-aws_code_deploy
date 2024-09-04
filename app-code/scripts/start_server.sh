#!/bin/bash

# Navigate to the app directory
cd /var/www/html/

# Install dependencies
sudo npm install

# Start the Node.js application
sudo nohup node index.js 2>&1 | sudo tee /var/log/app.log > /dev/null &

systemctl restart nginx
