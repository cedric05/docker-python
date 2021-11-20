# copied from https://raw.githubusercontent.com/docker-library/python/afc4106edc395bed8dfe7a497444033b12452406/3.9/buster/Dockerfile
# refer https://github.com/docker-library/python/blob/master/LICENSE

#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM buildpack-deps:stretch

RUN apt update \
	&& apt install build-essential checkinstall zlib1g-dev -y
WORKDIR /usr/local/src
RUN wget  https://www.openssl.org/source/openssl-1.1.1l.tar.gz \ 
	&& tar -xf  openssl-1.1.1l.tar.gz \
	&&  cd openssl-1.1.1l \
	&&  ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib \
        && make \
        #&& make test \
        && make install \
	&&  echo "/usr/local/ssl/lib" > /etc/ld.so.conf.d/openssl-1.1.1c.conf \
	&& cd .. \
	&& rm -rf *\
	&& ldconfig \
	&& mv /usr/local/ssl/bin/openssl /usr/bin/openssl # override openssl 

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# extra dependencies (over what buildpack-deps already includes)
RUN apt-get update && apt-get install -y --no-install-recommends \
		libbluetooth-dev \
		tk-dev \
		uuid-dev \
	&& rm -rf /var/lib/apt/lists/*

ENV GPG_KEY E3FF2839C048B25C084DEBE9B26995E310250568
ENV PYTHON_VERSION 3.10.0

RUN set -ex \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
# 	&& export GNUPGHOME="$(mktemp -d)" \
# 	&& gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
# 	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
# 	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
# 	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
		--with-openssl=/usr/local/ssl/ \
	&& ldconfig && make -j "$(nproc)" \
	&& make install \
	&& rm -rf /usr/src/python \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \
		\) -exec rm -rf '{}' + \
	\
	&& ldconfig \
	\
	&& python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 21.3
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://raw.githubusercontent.com/pypa/get-pip/21.3/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256 4ab6a1231fdce46e230d55947f6207c39e792d895da9197c2fec4143f5456a62

RUN set -ex; \
	\
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

CMD ["python3"]
