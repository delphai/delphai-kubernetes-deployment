import os

def get_release():
    repo_name = os.environ.get('REPOSITORY_NAME')
    branch_name = os.environ.get('GITHUB_REF_SLUG')
    release = ''
    if branch_name == 'master':
        release = repo_name
    else:
        release = f'{repo_name}-{branch_name}'
    return release

def get_namespace():
    return os.environ.get('REPOSITORY_NAME')