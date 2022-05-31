package uffizzi_create_preview_action

import (
    "dagger.io/dagger"
    "dagger.io/dagger/core"
    "universe.dagger.io/docker"
)
   
dagger.#Plan & {
    client: {
        env: {
            COMPOSE_FILE: string | *"docker-compose.yaml"
            UFFIZZI_USER: string 
            UFFIZZI_SERVER: string | *"https://app.uffizzi.com"
            UFFIZZI_PASSWORD: string 
            UFFIZZI_PROJECT: string 
            DOCKERHUB_USERNAME: string 
            DOCKERHUB_PASSWORD: string
        }
        filesystem: ".": read: {
            contents: dagger.#FS
        }
    }

    actions: {
        image: docker.#Pull & {
            source: "uffizzi/cli:2022-04-12"
        }
            
        create_preview: docker.#Run & {
            input: image.output
            mounts: source: core.#Mount & {
                type: "fs"
                source: "./"
                dest: "/source/"
                contents: client.filesystem.".".read.contents
            }
            command: {
                name: "preview"
                args: [ "create", "/source/"+client.env.COMPOSE_FILE]
            }
            always: true
            env: {
                UFFIZZI_SERVER: client.env.UFFIZZI_SERVER 
                UFFIZZI_USER: client.env.UFFIZZI_USER
                UFFIZZI_PASSWORD: client.env.UFFIZZI_PASSWORD 
                UFFIZZI_PROJECT: client.env.UFFIZZI_PROJECT 
                DOCKERHUB_USERNAME: client.env.DOCKERHUB_USERNAME
                DOCKERHUB_PASSWORD:client.env.DOCKERHUB_PASSWORD
            } 
        }
    }
}
