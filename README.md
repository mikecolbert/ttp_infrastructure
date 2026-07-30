# ttp_infrastructure

Docker infrastructure for [thetemperatureproject.org](https://thetemperatureproject.org)

---

## Build and Customize Your Linux Server

For now, I am using a linux virtual machine from Azure  
Ubuntu 24.04 LTS (no redundancy for test)  
Standard B1ms: 1 vCPU, 2GiB RAM, 1 thread per core  
Public/private key SSH authenication: Remember to `chmod 600` the private key.

`ssh -i <key> username@ip `

### Install updates and reboot the server

```
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo reboot
```

### Enable automatic security updates

Install unattended upgrades:  
`sudo apt install unattended-upgrades -y`

Enable unattended upgrades:  
`sudo dpkg-reconfigure unattended-upgrades`

Verify them:  
`systemctl status unattended-upgrades`

### Set the server in the correct time zone

To find the timezone name: `timedatectl list-timezones`

Set the timezone for this server:  
`sudo timedatectl set-timezone America/Chicago`

Verify the timezone details: `timedatectl`

### Install zsh

Install zsh: `sudo apt install zsh -y`

Configure zsh with robbyrussell:  
`sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"`

### Install helper utilities

```
sudo apt install btop -y
sudo apt install ca-certificates -y
sudo apt install curl -y
sudo apt install wget -y
sudo apt install git -y
sudo apt install tree -y
```

### Configure Git

```
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=720000'
git config --global user.email "*your email address*"
git config --global user.name "*your name*"
```

### Install uv for local tool management

Install uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`

Install pls via uv: `uv tool install pls`

### Add aliases for easier a managment

Add the following lines to your ~/.zshrc file: `sudo nano .zshrc`

```
alias http='docker run -it --rm --net=host clue/httpie'
alias glances='docker run --rm --name glances -v /var/run/docker.sock:/var/run/docker.sock:ro -v /run/user/1000/podman/podman.sock:/run/user/1000/podman/podman.sock:ro --pid host --network host -it docker.io/nicolargo/glances'
alias deploy="/cluster-src/book/ch11-example-setup/scripts/deploy.sh"
alias dc="docker compose"
alias lls="/bin/ls -G"
alias ls="pls"
```

Reload the zsh config to pick up the new aliases: `source ~/.zshrc`

### Add your user to the sudo group

`sudo usermod -aG sudo azureuser`

Log out and back in so the user picks up their new groups.

## Install Docker

Remove any old versions of Docker:  
`sudo apt remove docker docker-engine docker.io containerd runc`

Install Docker's repository:

```
sudo apt update

sudo apt install gnupg -y

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
```

Install Docker applications:

```
sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

```

<div class="callout-note" style="border-left: 4px solid blue; padding: 10px; background: #f0f4f8;">
<strong>IMPORTANT:</strong><br>
Change Docker data file to mounted volume if wanted, this will allow you to mount a separate volume much bigger than your hard drive and keep the docker working volumes and images there. This is especially useful if you have very large DB files in a persistent Docker volume.
See <a href="https://stackoverflow.com/questions/36014554/how-to-change-the-default-location-for-docker-create-volume-command">StackOverflow post</a>
Before you run anything related to Docker, be sure to change the docker working data to the mounted volume if you intend to do that.
</div>
<br/>
Verify docker is installed:

`docker --version`

and

`docker compose version`

### Allow your user to run Docker

`sudo usermod -aG docker $USER`

Log out and back in so the user picks up their new groups.

### Test Docker

`docker run hello-world`

### Set Docker to start automatically

Enable docker to start at boot:  
`sudo systemctl enable docker`

Verfiy:  
`sudo systemctl status docker`

### Create the persistent docker elements (network, disks, etc)

`docker network create -d bridge cluster-network --subnet=174.44.0.0/16`

Give the user ownership of /cluster-src and /cluster-data  
Once you sudo mkdir -p /cluster-src /cluster-data, those folders are owned by root. If you then try to git clone or nano .env into them as azureuser (not through sudo), you'll hit "permission denied." Cleanest fix, right after creating them:  
`sudo chown -R azureuser:azureuser /cluster-src /cluster-data`

## Clone repositories

Clone the infrastructure repository to /cluster-src/
`sudo git clone https://github.com/mikecolbert/ttp_infrastructure.git /cluster-src/`

Clone the application repository to the core-app's src folder
`cd /cluster-src/containers/core-app/ttp-docker/src`

`sudo git clone https://github.com/mikecolbert/ttp_app.git`

## Edit core-app files

Edit .dockerignore, Dockerfile, .env, and compose.yaml as needed.

## Test your application

### Build your core-app container

This container relies on linux-base -> python-base -> core-app

`cd /cluster-src/containers/core-app/`

`docker compose build`

### Start your core-app container

The -d flag runs the app in the background.  
`docker compose up -d`

Managing the docker container:

```
# Control the compose apps via:
docker compose down # shut down and clean up.
docker compose restart # restart (but not rebuild) all the containers.
docker compose logs -f -n 100 # Tail the combined logs (text output) of all containers.
```

### Connect to your application

http is an alias in your .zshrc file that pulls the docker image for HTTPie and runs it.  
`http -h localhost:15000`

You should see a _200 OK_ message returned from your app (-h is just pulling the reply header).

### Set your application container to launch on Linux startup

Run the script from the core-app folder that has the compose.yaml that builds your application.  
Change to the core-apps folder.  
`cd /cluster-src/containers/core-app/`

Run the script from that folder.  
`sudo bash /cluster-src/scripts/create-docker-compose-service.sh`

Verify by rebooting your server and testing that the application started.  
Reboot the server to verify the service is auto-starting.  
`sudo reboot`

Wait for the server to restart, then login.

Use httpie to call the app, should get 200 OK.  
`http -h localhost:15000`

You can also docker commands to test that the container is running.  
`docker ps`

## Configuring NGINX

We're not building a new docker image for NGINX. We are just using it out of the box from Docker Hub and adding our own configuration files.

Edit web-server/\* files as needed.

Create folders for logs, etc.

```
# Make the static folders for data exchange between the
# containers, git updates, and data exports
sudo mkdir -p /cluster-data/
sudo mkdir -p /cluster-data/nginx/static
sudo mkdir -p /cluster-data/nginx/logs
sudo mkdir -p /cluster-data/logs/video-collector

sudo mkdir -p /cluster-data/nginx/letsencrypt-etc
sudo mkdir -p /cluster-data/nginx/letsencrypt-www
sudo mkdir -p /cluster-data/nginx/certbot/www
```

### Launch NGINX with Docker Compose.

`cd /cluster-src/containers/web-servers/`
`docker compose up -d`

Test that the empty NGINX container is handling requests.  
`http -h localhost`

### Set your NGINX container to launch on Linux startup

`cd /cluster-src/containers/web-servers/`
`sudo bash /cluster-src/scripts/create-docker-compose-service.sh`

### Copy static files to NGINX

We will set the update script to do this automatically, but the first time we'll do it manually.

Make the destination directory.  
`sudo mkdir -p /cluster-data/nginx/static/the-temperature-project`

Copy the files.  
`sudo cp -r /cluster-src/containers/core-app/ttp-docker/src/ttp_app/static/* /cluster-data/nginx/static/the-temperature-project`

Verify the static folder contains file structure.  
`tree /cluster-data/nginx/static/the-temperature-project -d`

Reload NGINX's configuration files.  
`cd /cluster-src/containers/web-servers/`
`docker compose exec -t nginx nginx -s reload`

## Deploying changes to the application

After creating the custom scripts, you will need to make them executable.  
`sudo chmod +x /cluster-src/scripts/*.sh`

After this, you can use the `deploy` alias created in .zshrc to do the work.

---

## Configure Let's Encrypt for HTTPS

### Confirm DNS points to your server

`dig +short thetemperatureproject.org`  
Does the IP returned match the IP address of your server?

### Request the certificate

Move into the folder with the nginx + certbot compose.yaml.  
`cd /cluster-src/containers/web-servers/`

Ask certbot for a certificate, proving ownership via the shared webroot folder.  
`docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d thetemperatureproject.org`

Update NGINX configuration to use the certificate.  
`cd /cluster-src/containers/web-servers/nginx-base-configs/the-temperature-project.nginx`

```
server {
    server_name thetemperatureproject.org;
    charset utf-8;
    client_max_body_size 1M;
    server_tokens off;

    # Listen on the HTTPS port and point at the cert files certbot just created
    listen 443 ssl;
    http2 on;
    ssl_certificate /etc/letsencrypt/live/thetemperatureproject.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/thetemperatureproject.org/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location /static {
        gzip on;
        gzip_comp_level 6;
        gzip_min_length 1100;
        gzip_buffers 16 8k;
        gzip_proxied any;
        gzip_types
            text/plain
            text/xml
            text/css
            application/javascript
            application/json
            application/xml
            application/rss+xml;

        alias /static/the-temperature-project;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        expires 0;
    }

    # Lets certbot re-validate this domain later, when it's time to renew
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        try_files $uri @yourapplication;
    }
    location @yourapplication {
        gzip on;
        gzip_disable "msie6";
        gzip_comp_level 6;
        gzip_min_length 1100;
        gzip_buffers    8 256k;
        gzip_proxied any;
        gzip_types
            text/plain
            text/xml
            text/css
            application/javascript
            application/json
            application/xml
            application/rss+xml;

        # Hands the request off to the Granian app server
        proxy_pass http://174.44.0.100:15000;
        include uwsgi_params;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
    }
}

# Anything that still arrives on plain HTTP gets bounced to HTTPS
server {
    if ($host = thetemperatureproject.org) {
        return 301 https://$host$request_uri;
    }

    listen 80;
    server_name thetemperatureproject.org;
    return 404;
}
```

### Reload NGINX

`cd /cluster-src/containers/web-servers/`  
`docker compose exec -t nginx nginx -s reload`

Confirm it worked  
`curl -I https://thetemperatureproject.org`

I had errors and had to add do the following:

1. Create options-ssl-nginx.conf on the host, at the path that's mounted into both containers as /etc/letsencrypt/

```
sudo tee /cluster-data/nginx/letsencrypt-etc/options-ssl-nginx.conf > /dev/null << 'EOF'
# This file contains important security parameters. If you modify this file
# manually, Certbot will be unable to automatically provide future security
# updates. Instead, Certbot will print and log an error message with a path
# to the up-to-date file that you will need to refer to when manually
# updating this file.

ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
EOF
```

2. Generate ssl-dhparams.pem (Diffie-Hellman parameters — used to strengthen the key exchange).  
   `sudo openssl dhparam -out /cluster-data/nginx/letsencrypt-etc/ssl-dhparams.pem 2048`

Then reload and test again.  
`cd /cluster-src/containers/web-servers/`  
`docker compose exec -t nginx nginx -s reload`

Confirm it worked  
`curl -I https://thetemperatureproject.org`

It worked.

### Automate renewal

Let's Encrypt certificates expire every 90 days, so renewal has to run unattended.

Create _/cluster-src/scripts/renew-certs.sh_

Make it executable and schedule it.  
`sudo mkdir -p /cluster-data/logs/certbot`  
`sudo chmod +x /cluster-src/scripts/renew-certs.sh`  
`crontab -e`

Choose nano. Add this line to crontab:  
`0 3 * * * /cluster-src/scripts/renew-certs.sh >> /cluster-data/logs/certbot/renew.log 2>&1`

---

## Connect to a running Docker container

List running containers, get the name/ID:  
`docker ps`

Connect to the container:  
`docker exec -it <container> sh`  
-i keeps input open (interactive)  
-t gives you a proper terminal — together they make it feel like an SSH session  
-sh is the safe default you can use _-bash_ if the image has it

## TODO:

[ ] analytics  
[ ] monitoring  
[ ] other utils  
[ ] add second webstie  
[ ] how to persist data

Example: "docker volume create NAME" if you need a persistent volume,
our example doesn't use one.  
**_I may need to figure this out to hold the database._**.
