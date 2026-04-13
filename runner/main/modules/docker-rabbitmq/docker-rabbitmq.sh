#!/usr/bin/env bash
# RabbitMQ module – zwei Instanzen für MBS Integrationstests.

function docker-rabbitmq_env() {
    env=()
    echo "${env[@]}"
}

function docker-rabbitmq_check() {
    verify_modules docker
    verify_env NETWORK UUID
}

function docker-rabbitmq_config() {
    RABBITMQ1=rabbitmq"${UUID}"
    RABBITMQ2=rabbitmq2"${UUID}"
}

function docker-rabbitmq_setup() {
    echo
    echo ">>> startsection Starting RabbitMQ servers <<<"
    echo "============================================================================"
    docker run \
        --detach \
        --name "${RABBITMQ1}" \
        --hostname "rabbitmq" \
        --network "${NETWORK}" \
        --network-alias "rabbitmq" \
        -e RABBITMQ_DEFAULT_USER=guest \
        -e RABBITMQ_DEFAULT_PASS=guest \
        --health-cmd="rabbitmq-diagnostics check_running" \
        --health-interval=5s \
        --health-timeout=5s \
        --health-retries=12 \
        rabbitmq:3-management
    docker run \
        --detach \
        --name "${RABBITMQ2}" \
        --hostname "rabbitmq2" \
        --network "${NETWORK}" \
        --network-alias "rabbitmq2" \
        -e RABBITMQ_DEFAULT_USER=guest \
        -e RABBITMQ_DEFAULT_PASS=guest \
        --health-cmd="rabbitmq-diagnostics check_running" \
        --health-interval=5s \
        --health-timeout=5s \
        --health-retries=12 \
        rabbitmq:3-management
    echo "RabbitMQ 1: rabbitmq:5672"
    echo "RabbitMQ 2: rabbitmq2:5672"
    echo "============================================================================"
    echo ">>> stopsection <<<"
}