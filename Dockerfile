FROM delphairegistry/helm:latest
COPY . /app
RUN apt install jq -y
ENTRYPOINT [ "/app/deploy.sh" ]