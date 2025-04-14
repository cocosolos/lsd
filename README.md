<p align="center">
    <img width="256" height="256" src="lsd_logo_circle.png">
    <h1 align="center">LSB Server - Docker</h1>
</p>

<p align="center">Containerized version of <a href="https://github.com/LandSandBoat/server">LandSandBoat</a> server emulator.</p>

Pre-configured build and runtime environments for a fast and easy install. Supports live editing on the host machine for a seamless experience.

## Usage

`docker compose up --build --detach`

That's it! All the setup is handled for you. Check out the [official LSB documentation](https://github.com/LandSandBoat/server/wiki/Post-Install-Guide) for more information. Some adjustments will need to be made while working with [Docker](https://docs.docker.com/reference/). LSD specific information will be added here over time.

----

- `docker compose stop` / `docker compose start`
    - Use these to stop/start the server when rebuilding isn't necessary.

- `docker compose build`
    - Builds the image. With caching, this basically just rebuilds the executables if needed. Use `--no-cache` for a full clean build.

- `docker compose down`
    - Shuts down and removes the containers.

----

## Updating

- `git submodule update --remote --merge`
    - This will pull the latest changes from upstream LSB. Run `docker compose up --build --detach` again to rebuild and start/restart the containers.
    - You can also just change to the server directory and treat it as its own repo (change branch, fork, apply patches, etc.)

## Alpine

Alpine Linux is a minimal image that comes in at about half the size of the Ubuntu image (excluding bind mounted files/directories). The Alpine build is experimental and unsupported by LSB. It uses a newer version of GCC and the [musl libc](https://wiki.musl-libc.org/functional-differences-from-glibc.html). Use at your own risk.

`docker compose -f ./docker-compose.yml -f ./docker-compose.alpine.yml up --build --detach`

## Notes

- The image is built with a default user and group named `xiadmin` with UID and GID `1000`.
  - You can supply the build args `UNAME`, `UGROUP`, `UID`, `GID` to change these.
    - `docker compose build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" --build-arg UNAME="$(whoami)"`
- If using WSL with Windows, make sure [the project is stored in the WSL file system](https://learn.microsoft.com/en-us/windows/wsl/filesystems#file-storage-and-performance-across-file-systems) for best performance.
  - You may experience issues related to the system clock. Using `sudo hwclock --hctosys` in WSL may help.
- Secure database passwords and a default user and database name are generated into `config/.env` to simplify the setup process.
  - **Optional** - You can manually create this _before_ building the containers with these variables:
    ```
    MARIADB_DATABASE=
    MARIADB_USER=
    MARIADB_PASSWORD=
    MARIADB_ROOT_PASSWORD=
    ```
    Otherwise, the default user is `xiadmin`, the default database is `xidb`, and the password is randomly generated.
    - If `config/.env` is automatically generated, a random initial password for the root user will be generated and printed to stdout (check your build log!)
  - Because environment variables are used, the server settings `SQL_LOGIN`, `SQL_PASSWORD`, and `SQL_DATABASE` (all located in network.lua) are not used.
- Because LSB uses Git during the build and update process, changes to the Git metadata will trigger an image rebuild, but with caching this shouldn't be significant.

----

<p align="center">
    <img src="https://github.githubassets.com/images/icons/emoji/unicode/26a0.png?v8" />
    <h3 align="center">DO NOT OPEN ISSUES/DISCUSSIONS RELATED TO DOCKER ON THE LSB GITHUB!</h2>
</p>

----
