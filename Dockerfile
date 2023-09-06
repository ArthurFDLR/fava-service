ARG BEANCOUNT_VERSION=2.3.5
ARG FAVA_VERSION=v1.23.1

## Node build environment:
## Build a custom Fava
############################
ARG NODE_BUILD_IMAGE=16-bullseye
FROM node:${NODE_BUILD_IMAGE} as node_build_env
ARG FAVA_VERSION

WORKDIR /tmp/build

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3-babel

# Build Fava from source code with custom style.css
RUN git clone --depth 1 --branch ${FAVA_VERSION} https://github.com/beancount/fava
COPY ./style.css ./fava/frontend/css/style.css
RUN make -C ./fava

# Cleanup
RUN cd ./fava && \
    rm -rf .*cache && \
    rm -rf .eggs && \
    rm -rf .tox && \
    rm -rf build && \
    rm -rf dist && \
    rm -rf frontend/node_modules && \
    find . -type f -name '*.py[c0]' -delete && \
    find . -type d -name "__pycache__" -delete

## Application build environment:
## Used to build the final image
###################################
FROM debian:bullseye as build_env
ARG BEANCOUNT_VERSION

# Install dependencies
RUN apt-get update &&\ 
    apt-get install -y \ 
    build-essential libxml2-dev libxslt-dev curl python3 libpython3-dev python3-pip git python3-venv

# Setup the application as a Python Virtual Environment
ENV PATH "/app/bin:$PATH"
RUN python3 -m venv /app

# Collect pre-built Fava and dependencies list
COPY --from=node_build_env /tmp/build/fava /tmp/build/fava
COPY ./requirements.txt /tmp/build/requirements.txt

# Collect Beancount source code
WORKDIR /tmp/build
RUN git clone --depth 1 --branch ${BEANCOUNT_VERSION} https://github.com/beancount/beancount

# Install Beancount, Fava and other dependencies
RUN CFLAGS=-s pip3 install -U /tmp/build/beancount && \
    pip3 install -U /tmp/build/fava && \
    pip3 install -U -r /tmp/build/requirements.txt && \
    pip3 uninstall -y pip

# Cleanup
RUN find /app -name __pycache__ -exec rm -rf -v {} +


## Final image:
## Used to run the application
## Environment variables:
## - LEDGER_GIT: Remote address of the ledger repository
## - BEAN_FILE: Path to the main Beancount file in the repository (e.g. ledger/my_finances.bean)
###############################
FROM python:3.9-slim-bullseye

# Copy the application from the build environment
COPY --from=build_env /app /app

# Install Git and Cron
RUN apt update && \
    apt install -y git cron rsyslog && \
    apt clean

# Set working directory
WORKDIR /app

# Copy the Bash scripts and the configuration file
COPY pull_ledger.sh /app/
COPY entrypoint.sh /app/
COPY app.conf /app/

# Make the script executable
RUN chmod +x /app/pull_ledger.sh
RUN chmod +x /app/entrypoint.sh

# Add the application to the PATH
ENV PATH "/app/bin:$PATH"

# Setup the cron job, runs every hour
RUN (echo "0 * * * * /app/pull_ledger.sh >> /app/pull_ledger.log 2>&1") | crontab -

# Default fava port number
EXPOSE 5000

# Default Fava host
ENV FAVA_HOST "0.0.0.0"

# TODO: Remove this once the fava issue is fixed
RUN ln -s /usr/local/bin/python3 /usr/bin/python3

ENTRYPOINT ["/app/entrypoint.sh"]
