# Setup a Python virtual environment
FROM python:3.9.13-slim-bullseye as python-builder
RUN apt-get update && apt upgrade -y && pip install pipenv
WORKDIR /opt/app
COPY ./requirements.txt .
ENV PIPENV_VENV_IN_PROJECT=1
RUN pipenv install --three

# Build the transifex-cli go static binary
FROM golang:1-bullseye as go-builder
WORKDIR /opt/app
RUN git clone https://github.com/transifex/cli .
# Fetch latest released version and build it from source
RUN git fetch --tags && latestTag=$(git describe --tags `git rev-list --tags --max-count=1`) && git checkout $latestTag
RUN make build

# Gather the build artifacts
FROM python:3.9.13-slim-bullseye
WORKDIR /opt/app
COPY . .
COPY --from=python-builder /opt/app/.venv/ .venv/
COPY --from=go-builder /opt/app/bin/tx /bin/

CMD . .venv/bin/activate && mkdocs serve -a 0.0.0.0:8000