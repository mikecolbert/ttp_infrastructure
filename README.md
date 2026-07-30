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

---

### Create the persistent docker elements (network, disks, etc)

`docker network create -d bridge cluster-network --subnet=174.44.0.0/16`

TODO:
Example: "docker volume create NAME" if you need a persistent volume,
our example doesn't use one.  
**_I may need to figure this out to hold the database._**.

One more small thing: once you sudo mkdir -p /cluster-src /cluster-data, those folders are owned by root. If you then try to git clone or nano .env into them as azureuser (not through sudo), you'll hit "permission denied." Cleanest fix, right after creating them:

`sudo chown -R azureuser:azureuser /cluster-src /cluster-data`

## That hands the folders to your everyday user so all the subsequent git/edit/copy steps in the book work without a sudo in front of every line — same end state as the book's root-owns-everything setup, just reached the Azure way.

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
