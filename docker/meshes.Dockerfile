FROM busybox:latest

ADD https://github.com/EdenServer/losmeshes.git /losmeshes
ADD https://github.com/LandSandBoat/xiNavmeshes.git /navmeshes

VOLUME /navmeshes /losmeshes