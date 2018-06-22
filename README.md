# docker-backup-restore

This tool allows the user to do the following operations on docker containers created with docker or docker-compose:

- Backup
- Restore
- Move containers and docker-compose container sets between machines.

## docker-compose Usage

**Test this procedure before using it.**

- Create your `docker-compose.yml` file. Make sure that all volumes that need to be backed up are named. Here's an example:

    services:
      postgres:
        image: postgres:10
        environment:
          POSTGRES_USER: someuser
          POSTGRES_PASSWORD: somepassword
        volumes:
          - database:/var/lib/postgresql/data
        restart: always
    volumes:
      database:

- Run `docker-compose up -d` on this file.
- Do whatever you want to configure the container, add data, etc.
- `cd` to the path that has the docker-compose file
- Download `docker-backup.sh` and put it in the same folder as the docker-compose file.
- Make `docker-backup.sh` executable like this: `chmod +x docker-backup.sh`
- Create a file for backing up and restoring your stack. Let's name it `postgres_backup.sh`. Give it the following contents:

    #!/usr/bin/env bash

    ACTION=$1
    
    # You can add all your containers here. Once a container is running,
    # the backup operation automatically detects what volumes it has and backs them up.
    ./docker-backup.sh $ACTION drupal_postgres_1

    # The script isn't smart enough to know what the container IDs for the docker-compose file are,
    # so you have to have a separate line for each container:
    #./docker-backup.sh $ACTION myservice2
    #./docker-backup.sh $ACTION myservice3

- This file will be used to backup and restore the Docker application
- Make this file executable: `chmod +x postgres_backup.sh`
- Back up the application by running `./postgres_backup.sh backup`
- WARNING: this will stop your docker-compose application, but you won't lose the data in your volumes.
- If you want to start the docker-compose application again, run `docker-compose up -d` after the backup is done.
- The backup creates a folder for each container that was backed up.
  - Each folder contains a `*.tar` file for each volume in that container.
  - Each container has a single file named `volumes.txt` which contains the list of volumes and mountpoints for that container.
- To restore a backup, change the docker-compose file so that all the volumes are external, and have the `<COMPOSER_PROJECT>_VOLUME`. So for example, if your `docker-compose.yml` is in the folder `postgres`, the `docker-compose.yml` file should look like this:

    services:
      postgres:
        image: postgres:10
        environment:
          POSTGRES_USER: someuser
          POSTGRES_PASSWORD: somepassword
        volumes:
          - database:/var/lib/postgresql/data
        restart: always
    volumes:
      database:
        external:
          name: postgres-database

- Once this has been done, you can `docker-compose kill` and `docker-compose rm -v` to remove any containers and volumes created by docker-compose.
- To do the actual restore, run `./postgres-backup restore`.
- To start the newly-restored application, run `docker-compose up -d`.
- Your service should be accessible now.

## To-do

Here are some things that need to be done next on this repository:

- Make the script automatically detect the containers in the docker-compose file. (This might require switching to a different language than bash, ugh.)
- Snapshot the containers before backing them up. I think this might make it unnecessary to kill the docker-compose application when backing it up.
