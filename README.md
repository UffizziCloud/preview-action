# Uffizzi Preview docker action

This action quickly deploys a Continuous Preview per a specified compose file.

## Inputs

## `compose-file`

**Required** Path to a compose file within your repository.

## Outputs

## `foo`

The bar you baz.

## Example usage

uses: UffizziCloud/preview-action@v1
with:
  compose-file: 'docker-compose.uffizzi.yaml'
