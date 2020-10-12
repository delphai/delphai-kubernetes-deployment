FROM python:3.8
WORKDIR /app
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" 
RUN chmod +x ./kubectl 
RUN mv /app/kubectl /usr/local/bin/kubectl 
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
COPY . /app
ENTRYPOINT [ "/app/src/start.sh" ]