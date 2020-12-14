FROM delphairegistry/dind-az-kctl-helm:main 
COPY . /app
CMD /app/deployment/deploy.sh