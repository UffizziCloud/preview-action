# Uffizzi Preview docker action

This action quickly deploys a Continuous Preview per a specified compose file.

## Inputs

### `compose-file`

**Required** Path to a compose file within your repository

### `username`

**Required** Uffizzi username

### `project`

**Required** Uffizzi project name

### `hostname`

URL of your Uffizzi installation

## Secrets

### `UFFIZZI_PASSWORD`

Your Uffizzi password. Specify a GitHub Encrypted Secret with this name.

## Example usage

```yaml
uses: UffizziCloud/preview-action@v1
with:
  compose-file: 'docker-compose.uffizzi.yaml'
  username: 'admin@uffizzi.com'
  hostname: 'https://app.uffizzi.com'
  project: 'default'
```
