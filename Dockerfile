FROM delphairegistry/helm:latest
COPY . /app
RUN apt install jq -y
CMD /app/deploy.sh