FROM python:3.8
LABEL maintainer="delphai/devops"
WORKDIR /app
#RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
COPY . /app
RUN chmod +x /app/src/deploy.sh
ENTRYPOINT [ "/app/src/deploy.sh" ]