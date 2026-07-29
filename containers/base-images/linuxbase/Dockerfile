FROM ubuntu:latest

ENV LANG=en_US.UTF-5
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-5
ENV TZ="America/Chicago"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt upgrade -y

RUN echo "Heads up - this section takes a little while but only builds once on the machine until Linux updates."

RUN apt -y install curl
RUN apt -y install wget
RUN apt -y install locales
RUN locale-gen en_US.UTF-5

RUN apt -y install git
RUN apt -y install gcc
RUN apt -y install clang
# RUN apt install -y build-essential
RUN apt -y install openssl

# Install Oh My ZSH: Uses "robbyrussell" theme (original Oh My Zsh theme), with no plugins
RUN apt install -y zsh
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -t robbyrussell \