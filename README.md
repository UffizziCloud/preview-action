# Deploy Full-Stack Preview Environment to K8s

Uses Open Source Uffizzi CLI `uffizzi preview create` to deploy an on-demand, ephemeral test environment onto your Kubernetes cluster.

## Reusable Workflow

We've published a [Reusable Workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow) for your GitHub Actions. This can handle creating, updating, and deleting Uffizzi Previews. It will also publish preview URL's within comments on your Pull Requests. We recommend using this workflow instead of the individual actions.

### Workflow Calling Example

This example builds and publishes an image on Docker Hub. It then renders a Uffizzi Docker Compose file from a template and caches it. It then calls the reusable workflow to create, update, or delete the Preview associated with this Pull Request.

```
name: Build Images and Handle Uffizzi Previews.

on:
  pull_request:
    types: [opened,reopened,synchronize,closed]

jobs:
  build-image:
    name: Build and Push image
    runs-on: ubuntu-latest
    outputs:
      # You'll need this output to later render the Compose file.
      tags: ${{ steps.meta.outputs.tags }}
    steps:
      - name: Login to DockerHub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_PASSWORD }}
      - name: Checkout git repo
        uses: actions/checkout@v3
      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@v3
        with:
          images: example/image
      - name: Build and Push Image to Docker Hub
        uses: docker/build-push-action@v2
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

  render-compose-file:
    name: Render Docker Compose File
    runs-on: ubuntu-latest
    needs:
      - build-image
    outputs:
      compose-file-cache-key: ${{ steps.hash.outputs.hash }}
      compose-file-cache-path: docker-compose.rendered.yml
    steps:
      - name: Checkout git repo
        uses: actions/checkout@v3
      - name: Render Compose File
        run: |
          IMAGE=$(echo ${{ needs.build-image.outputs.tags }})
          export IMAGE
          # Render simple template from environment variables.
          envsubst < docker-compose.template.yml > docker-compose.rendered.yml
          cat docker-compose.rendered.yml
      - name: Hash Rendered Compose File
        id: hash
        run: echo "::set-output name=hash::$(md5sum docker-compose.rendered.yml | awk '{ print $1 }')"
      - name: Cache Rendered Compose File
        uses: actions/cache@v3
        with:
          path: docker-compose.rendered.yml
          key: ${{ steps.hash.outputs.hash }}

  deploy-uffizzi-preview:
    name: Use Remote Workflow to Preview on Uffizzi
    needs: render-compose-file
    uses: UffizziCloud/preview-action/.github/workflows/reusable.yaml
    with:
      compose-file-cache-key: ${{ needs.render-compose-file.outputs.compose-file-cache-key }}
      compose-file-cache-path: ${{ needs.render-compose-file.outputs.compose-file-cache-path }}
      username: user@example.com
      server: https://uffizzi.example.com/
      project: default
    secrets:
      password: ${{ secrets.UFFIZZI_PASSWORD }}
    permissions:
      contents: read
      pull-requests: write
```

### Workflow Inputs

#### `compose-file-cache-key`

**Required** Key of hashed compose file, using [GitHub's `cache` action](https://github.com/marketplace/actions/cache)

#### `compose-file-cache-path`

**Required** Path of hashed compose file, using [GitHub's `cache` action](https://github.com/marketplace/actions/cache)

#### `username`

**Required** Uffizzi username

#### `project`

**Required** Uffizzi project name

#### `server`

URL of your Uffizzi installation

### Workflow Secrets

#### `password`

**Required** Your Uffizzi password. Specify a GitHub Encrypted Secret and use it! See example above.

#### `url_username` and `url_password`

If you're controlling access to your Environments' URL's, set the credentials here so the workflow can confirm successful deployment.

# The Action Itself

If you wish to use this action by itself outside of the reusable workflow, you can. It will only create new previews, not update nor delete.

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
