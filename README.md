# Delphai Main Deployment Action

![GitHub repo size](https://img.shields.io/github/repo-size/scottydocs/README-template.md)
![GitHub contributors](https://img.shields.io/github/contributors/scottydocs/README-template.md)

This is a Github action for delphai app deployments into Azure K8s Clusters.

## Important Information

``` python

domains = {
    "common" : "delphai.red",
    "review" : "delphai.pink",
    "development": "delphai.black",
    "staging"  : "delphai.blue"
     
}

```

``` 
url = https://api.${domain}/${repo_name}-${branch_name}/function

```
