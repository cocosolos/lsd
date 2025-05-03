<p align="center">
    <img width="256" height="256" src="lsd_logo_circle.png">
    <h1 align="center">LSB Server - Docker</h1>
</p>

<p align="center">
Containerized version of <a href="https://github.com/LandSandBoat/server">LandSandBoat</a> server emulator.<br>
Pre-configured build and runtime environments for a fast and easy install.
</p>

## Using

See `docker-compose.yml` for example usage.

The following environment variables are required to connect to a database:
```
MARIADB_DATABASE or XI_NETWORK_SQL_DATABASE
MARIADB_USER or XI_NETWORK_SQL_LOGIN
MARIADB_PASSWORD or XI_NETWORK_SQL_PASSWORD
```

If you're setting up a database using the MariaDB image, one of `MARIADB_ROOT_PASSWORD_HASH`, `MARIADB_ROOT_PASSWORD`, `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD`, or `MARIADB_RANDOM_ROOT_PASSWORD` (or equivalents, including `*_FILE`), is also required (along with the `MARIADB_` variants of the above variables).

You should create and mount an empty `config.yaml` file so that dbtool can use express updates when new images are pulled.

## Building

`./build.sh -t ubuntu`

This will build the latest LSB server image based on Ubuntu. Navmeshes and Losmeshes are not included in this image.

`./build.sh -t meshes`

This will build the latest navmeshes and losmeshes from their upstream repositories. This may not match the exact versions LSB uses (Eden maintains losmeshes). After building the meshes image, run the image with the following command:

`docker run --rm -v losmeshes:/losmeshes -v navmeshes:/navmeshes ximeshes:latest`

This will copy the losmeshes and navmeshes into a local volume that can be mounted into the server image. You can delete the ximeshes image after the volumes are created.

----

## Alpine

Alpine Linux is a minimal image that is smaller than the Ubuntu image. The Alpine build is experimental and unsupported by LSB. It uses a newer version of GCC and the [musl libc](https://wiki.musl-libc.org/functional-differences-from-glibc.html). Use at your own risk.

## Notes

- The image is built with a default user and group named `xiadmin` with UID and GID `1000`.
  - You can supply the build args `UNAME`, `UGROUP`, `UID`, `GID` to change these.
    - `docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" --build-arg UNAME="$(whoami)" -f docker/ubuntu.Dockerfile .`
- `build.sh` has options to build a specific origin/branch other than LandSandBoat/base.

----

<p align="center">
    <img src="https://github.githubassets.com/images/icons/emoji/unicode/26a0.png?v8" />
    <h3 align="center">DO NOT OPEN ISSUES/DISCUSSIONS RELATED TO DOCKER ON THE LSB GITHUB!</h2>
</p>

----
