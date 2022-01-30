# ---------------------------------------------------------------------------
# Builder Image
# ---------------------------------------------------------------------------
FROM alpine:3.12.0@sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321 as builder

# Required tools for building Python packages
RUN set -eux \
	&& apk add --no-cache \
		bc \
    ca-certificates \
		gcc \
		libffi-dev \
		make \
		musl-dev \
		openssl-dev \
		python3 \
		python3-dev \
		py3-pip

RUN mkdir -p ~/.local/bin

ENV PATH=$HOME/.local/bin:$PATH

COPY requirements.in /requirements.in

# see https://stackoverflow.com/questions/66118337/how-to-get-rid-of-cryptography-build-error
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

RUN \
  pip3 install --upgrade pip wheel pip-tools setuptools && \
  pip-compile /requirements.in --output-file /requirements.txt && \
  pip3 install --user -r /requirements.txt

COPY requirements.in /requirements.in

RUN \
  pip3 wheel -w /opt/wheel/ -r requirements.in


# ----------------------------------------------------------------------------
# Final Image
# ----------------------------------------------------------------------------

FROM alpine:3.12.0@sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321 as production

# Metadata labels



RUN set -eux \
	&& apk add --no-cache \
    bash \
    ca-certificates \
    git \
    openssh-client \
    py3-pip \
    python3 \
    sudo

RUN mkdir -p ~/.local/bin

ENV HOME=/root
ENV PATH=$HOME/.local/bin:$PATH

COPY --from=builder /opt/wheel /opt/wheel

RUN \
  pip3 install --upgrade pip && \
  pip3 install /opt/wheel/* && \
  rm -rf /opt/wheel

# create a user
ARG user_uid=1001
ARG user_gid=1001

ENV user_uid=$user_uid
ENV user_gid=$user_gid

RUN : "adding user" && \
  addgroup -g $user_gid user && \
  adduser  -D -G user -u $user_uid -g '' user && \
  echo '%user ALL=(ALL) NOPASSWD:ALL' | tee -a /etc/sudoers

USER user
ENV HOME=/home/user
WORKDIR $HOME

RUN \
  mkdir -p $HOME/.local/bin

ENV PATH=/home/user/.local/bin:$PATH



