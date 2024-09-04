#!/bin/bash

# Navigate to the app directory
cd /var/www/html/

# Install dependencies
npm install

systemctl restart nginx

# Start the Node.js application
npm start &