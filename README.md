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
    - Builds the image. With caching, this basically means rebuild the executables.

- `docker compose down`
    - Shuts down and deletes the containers.

----

## Updating

- `git submodule update --remote --merge`
    - This will pull the latest changes from upstream LSB. Run `docker compose up --build --detach` again to rebuild and start/restart the containers.

## Notes

- If using WSL with Windows, make sure [the project is stored in the WSL file system](https://learn.microsoft.com/en-us/windows/wsl/filesystems#file-storage-and-performance-across-file-systems) for best performance.
- To facilitate automatically generating secure database passwords and simplify the setup process, the `.env` file is intentionally empty and untracked by Git.
  - **Optional** - You can manually populate this _before_ building the containers with these variables:
    ```
    MARIADB_DATABASE=
    MARIADB_USER=
    MARIADB_PASSWORD=
    MARIADB_ROOT_PASSWORD=
    XI_NETWORK_ENABLE_HTTP=
    ```
    Otherwise, the default user is `xiadmin`, the default database is `xidb`, and both passwords are randomly generated.
  - The LSB HTTP API is enabled by default and can be accessed at http://localhost:8088/.
    - This can be disabled by setting `XI_NETWORK_ENABLE_HTTP=0`
  - Because environment variables are used, the server settings `SQL_LOGIN`, `SQL_PASSWORD`, `SQL_DATABASE`, and `ENABLE_HTTP` (located in network.lua) are not used.
- Because LSB uses Git during the build and update process, changes to the Git metadata will trigger an image rebuild, but with caching this shouldn't be significant.

----

<p align="center">
    <img src="https://github.githubassets.com/images/icons/emoji/unicode/26a0.png?v8" />
    <h3 align="center">DO NOT OPEN ISSUES/DISCUSSIONS RELATED TO DOCKER ON THE LSB GITHUB!</h2>
</p>

----
