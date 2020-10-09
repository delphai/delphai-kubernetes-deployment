FROM node:12.18.4
WORKDIR /app
COPY . /app
ENTRYPOINT [ "/app/src/start.sh" ]