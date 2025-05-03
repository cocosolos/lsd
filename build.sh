#!/bin/bash

Help()
{
   echo "Builds LSB images."
   echo
   echo "Syntax: build.sh [-t ubuntu|alpine|meshes] [-o <origin>] [-b <branch>]"
   echo "options:"
   echo "t     Target image to build."
   echo "o     Source origin. (default: LandSandBoat)"
   echo "b     Source branch. (default: base)"
   echo
}

TARGET=""
ORIGIN="LandSandBoat"
BRANCH="base"
TAG="latest"

while getopts ":t:o:b:" option; do
    case $option in
        t)
            TARGET=$OPTARG
            ;;
        o)
            ORIGIN=$OPTARG
            ;;
        b)
            BRANCH=$OPTARG
            TAG=$BRANCH
            ;;
        \?)
            Help
            exit
            ;;
    esac
done

if [[ -n $TARGET ]]; then
    if [[ $TARGET == "meshes" ]]; then
        TAG="ximeshes:latest"
    else
        if [[ $TARGET == "alpine" ]]; then
            TAG="$TAG-alpine"
        fi
        TAG=$(echo "$ORIGIN-server:$TAG" | tr '[:upper:]' '[:lower:]')
    fi

    echo "Building $TAG..."
    docker build -t $TAG --build-arg ORIGIN=$ORIGIN --build-arg BRANCH=$BRANCH -f docker/$TARGET.Dockerfile .
else
    Help
fi
