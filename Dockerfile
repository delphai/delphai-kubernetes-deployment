FROM delphairegistry/helm:latest
COPY . /app
ENTRYPOINT [ "/app/src/start.sh" ]