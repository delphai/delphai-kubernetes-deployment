FROM python:3.8
LABEL maintainer="delphai/devops"
WORKDIR /app
#RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash 
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN  apt install apt-transport-https ca-certificates curl software-properties-common
RUN  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic test"
RUN apt update

RUN  apt install libseccomp2>= 2.4.0 docker-ce containerd.io 
RUN sleep 30
RUN docker 
COPY . /app
RUN chmod +x /app/src/deploy.sh
ENTRYPOINT [ "/app/src/deploy.sh" ]