FROM delphairegistry/helm:latest
COPY . /app
RUN apt install jq -y
RUN chmod 777 /app/deploy.sh
ENTRYPOINT [ "/app/deploy.sh" ]