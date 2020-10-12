import os

enviroment = os.environ.get('INPUT_DELPHAI_ENVIROMENT')

domains = {
    "common" : "delphai.red",
    "review" : "delphai.pink",
    "development": "delphai.black",
     
}

os.environ['DOMAIN'] = domains[enviroment]
print(domains["common"])