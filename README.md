# On-demand Preview Environments

Deploy a Preview Environment for every pull request. Supports APIs, frontends, backends, databases, microservices, binaries and command-line tools.

Uffizzi integrates as a step in your GitHub Actions pipeline to manage on-demand, ephemeral test environments for every feature branch/pull request. Preview Environments are deployed on [Uffizzi Cloud](https://uffizzi.com) (SaaS) or your own installation of [open-source Uffizzi](https://github.com/UffizziCloud/uffizzi_app) (self-hosting requires Kubernetes).

## Reusable Workflow (recommended)

We've published a [Reusable Workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow) for your GitHub Actions. This can handle creating, updating, and deleting Uffizzi Preview Environments. It will also publish Preview Environment URLs as a comment to your pull request issues.

💡 We recommend using this reusable workflow instead of using the individual actions for [create](https://github.com/UffizziCloud/preview-action), [update](https://github.com/UffizziCloud/update-preview-action), and [delete](https://github.com/UffizziCloud/delete-preview-action).

### Workflow Calling Example

This example builds and publishes an image to Docker Hub for pull request events. It then renders a Docker Compose file from a template and caches it. Finally, it calls the reusable workflow to create, update, or delete the Preview Environment associated with the pull request.

```yaml
name: Build Images and Handle Uffizzi Previews.

on:
  pull_request:
    types: [opened,reopened,synchronize,closed]

jobs:
  build-image:
    name: Build and Push image
    runs-on: ubuntu-latest
    outputs:
      # You'll need this output later to render the Compose file.
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
    uses: UffizziCloud/preview-action/.github/workflows/reusable.yaml@v2
    if: ${{ github.event_name == 'pull_request' && github.event.action != 'closed' }}
    with:
      compose-file-cache-key: ${{ needs.render-compose-file.outputs.compose-file-cache-key }}
      compose-file-cache-path: ${{ needs.render-compose-file.outputs.compose-file-cache-path }}
      server: https://app.uffizzi.com/
    permissions:
      contents: read
      pull-requests: write
      id-token: write

  delete-uffizzi-preview:
    name: Use Remote Workflow to Delete an Existing Preview
    uses: UffizziCloud/preview-action/.github/workflows/reusable.yaml@v2
    if: ${{ github.event_name == 'pull_request' && github.event.action == 'closed' }}
    with:
      compose-file-cache-key: ''
      compose-file-cache-path: docker-compose.rendered.yml
      server: https://app.uffizzi.com/
    permissions:
      contents: read
      pull-requests: write
      id-token: write
```

### Workflow Inputs

#### `compose-file-cache-key`

(Required) Key of hashed compose file, using [GitHub's `cache` action](https://github.com/marketplace/actions/cache)

Note that if this is an emtpy string, the reusable workflow will delete the preview associated with this Pull Request.

#### `compose-file-cache-path`

(Required) Path of hashed compose file, using [GitHub's `cache` action](https://github.com/marketplace/actions/cache)

#### `server`

(Required) `https://app.uffizzi.com/` or the URL of your Uffizzi installation

#### `pr-number`

(Optional) If you're calling this workflow from a workflow that's not triggered by `pull_request`, you may want to specify the PR number here.

#### `git-ref`

(Optional) If you're calling this workflow from a workflow that's not triggered by `pull_request`, you may want to specify the branch or other git reference here.

#### `url-username` and `url-password`

(Optional) If you're controlling access to the URLs of your Preview Environments, set the credentials here so the workflow can confirm successful deployment.

#### `healthcheck-url-path`

URL path that will be appended to the preview URL where the reusable workflow will check for the health of the preview. URL path has to start with `/`. Use this if the root URL of your application does not return an HTTP response code below 400.

## Uffizzi Accounts

If you're using the reusable workflow with [Uffizzi Cloud](https://uffizzi.com), an account and project will be created from your GitHub user and repository information when the workflow runs. If you're self-hosting open-source Uffizzi, you will need to create a Uffizzi user and project before running the workflow, then set `username`, `password`, and `project` inputs, where `project` is the Uffizzi project slug.

### Example usage Uffizzi Cloud

```yaml
uses: UffizziCloud/preview-action@v2
with:
  compose-file: 'docker-compose.uffizzi.yaml'
  server: 'https://app.uffizzi.com'
permissions:
  contents: read
  pull-requests: write
  id-token: write
```

### Example usage self-hosted

```yaml
uses: UffizziCloud/preview-action@v2
with:
  compose-file: 'docker-compose.uffizzi.yaml'
  server: 'https://uffizzi.example.com'
  username: 'j.doe@example.com'
  password: ${{ secrets.UFFIZZI_PASSWORD }}
  project: 'default'
permissions:
  contents: read
  pull-requests: write
  id-token: write
```

## Using this Preview Action itself (not recommended)

If you wish to use this action by itself outside of the reusable workflow described above, you can. It will only create new previews, not update nor delete them.

### Inputs

#### `compose-file`

(Required) Path to a compose file within your repository

#### `server`

(Required) `https://app.uffizzi.com/` or the URL of your Uffizzi installation

#### `username`

(Self-hosted only) Uffizzi username

#### `password`

(Self-hosted only) Your Uffizzi password, specified as a GitHub Secret

#### `project`

(Self-hosted only) Uffizzi project slug

#### `ghcr-username` and `ghcr-access-token`

Your GitHub username and the value of a [Github personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with access to the `read:packages` scope.

This option is provided as a convenience to get started quickly. For sensitive repositories, we recommend instead connecting your Uffizzi account to GHCR via the web interface or by executing `uffizzi connect ghcr` from a trusted environment.

#### `dockerhub-username` and `dockerhub-password`

Your DockerHub username and password.

### `acr-registry-url`, `acr-username`, and `acr-password`

Your Azure Container Registry url, username and password.

### `aws-registry-url`, `aws-access-key-id`, and `aws-secret-access-key`

Your Amazon Web Services registry url, access key id and secret access key.

### `gcloud-service-key`

Your Google Cloud service key.

### `docker-registry-url`, `docker-registry-username`, and `docker-registry-password`

Your custom docker registry url, username and password.

## Example usage

```yaml
uses: UffizziCloud/preview-action@v2
with:
  compose-file: 'docker-compose.uffizzi.yaml'
  username: 'admin@uffizzi.com'
  server: 'https://app.uffizzi.com'
  project: 'default'
  password: ${{ secrets.UFFIZZI_PASSWORD }}
permissions:
  contents: read
  pull-requests: write
  id-token: write
```

## If you don't have a Uffizzi account

If you don't have a Uffizzi account, leave the username, password and project inputs blank. Uffizzi will create a Uffizzi account based on the information about the current repository and Github user.

Example usage without an account:

```yaml
uses: UffizziCloud/preview-action@v2
with:
  compose-file: 'docker-compose.uffizzi.yaml'
  server: 'https://app.uffizzi.com'
permissions:
  contents: read
  pull-requests: write
  id-token: write
```
