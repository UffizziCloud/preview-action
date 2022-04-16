# Deploy Full-Stack Preview Environment to K8s

Open Source Uffizzi CLI `uffizzi preview create` to deploy an on-demand, ephemeral test environment onto your Kubernetes cluster.

## Inputs

### `compose-file`

**Required** Path to a compose file within your repository

### `username`

**Required** Uffizzi username

### `project`

**Required** Uffizzi project name

### `server`

URL of your Uffizzi installation

### `password`

Your Uffizzi password. Specify a GitHub Encrypted Secret and use it! See example below.

## Example usage

```yaml
uses: UffizziCloud/preview-action@v2
with:
  compose-file: 'docker-compose.uffizzi.yaml'
  username: 'admin@uffizzi.com'
  server: 'https://app.uffizzi.com'
  project: 'default'
  password: ${{ secrets.UFFIZZI_PASSWORD }}
```
