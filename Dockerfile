FROM node:12
WORKDIR /app
COPY . /app
ENTRYPOINT [ "/app/src/start.sh" ]