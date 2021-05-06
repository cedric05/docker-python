# docker-python3.9


python relies on c++ std library (glib).

standard [python](https://github.com/docker-library/python/blob/df24861e935b54ed6f28c0fb3e4646fc7dbc85c2/3.9/buster/Dockerfile) image from docker hub is built from buildpack-deps:buster.

buster uses libc of version [https://packages.debian.org/buster/libc](2.28).

most workplace/home computers are not yet upgraded to latest libc. for using applications developed python3.9, prebuilt version is no longer useable outside docker, users always have to install python by downloading tar file and build it locally, which puts us in difficult posistion.


Current repository uses [debian-stretch](https://packages.debian.org/stretch/libc6) to build python3.9.
