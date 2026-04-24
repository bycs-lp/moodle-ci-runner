#!/usr/bin/env bash
#
# This file is part of the Moodle Continuous Integration Project.
#
# Moodle is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Moodle is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Moodle.  If not, see <https://www.gnu.org/licenses/>.

# Functions needed to init the database.
# This database supports both standalone and primary-replica setups.

# Print runtime diagnostics without breaking the job if checks fail.
function mysqli_print_runtime_diagnostics() {
    local container="$1"
    local role="$2"

    echo "--- MYSQL-DIAG [${role}] container=${container} ---"
    if ! docker exec "${container}" sh -c 'echo "Config files in /etc/mysql/conf.d:"; ls -1 /etc/mysql/conf.d'; then
        echo "WARNING: MYSQL-DIAG [${role}] cannot list /etc/mysql/conf.d"
    fi

    if ! docker exec "${container}" mysql -u root -p"${DBPASS}" -N -B -e "SHOW VARIABLES WHERE Variable_name IN ('log_bin','log_bin_basename','datadir','server_id','binlog_expire_logs_seconds','max_binlog_size');"; then
        echo "WARNING: MYSQL-DIAG [${role}] cannot query MySQL variables"
    fi
    echo "--- /MYSQL-DIAG [${role}] ---"
}

# Init a standalone database container. Without replicas.
function mysqli_config_standalone() {
    echo "Starting standalone database..."
    docker run \
        --detach \
        --name "${DBHOST}" \
        --network "${NETWORK}" \
        -e MYSQL_DATABASE="${DBNAME}" \
        -e MYSQL_ROOT_PASSWORD="${DBPASS}" \
        -e MYSQL_USER="${DBUSER}" \
        -e MYSQL_PASSWORD="${DBPASS}" \
        --tmpfs /var/lib/mysql:rw,noexec,nosuid,size=4096m \
        -v "${HOSTBASEDIR}/modules/docker-database/mysqli.d/standalone/conf.d:/etc/mysql/conf.d" \
        mysql:"${DBTAG}"

    # Wait few secs, before executing commands.
    # TODO: Find a better way to wait for the database to be ready.
    sleep 20

    mysqli_print_runtime_diagnostics "${DBHOST}" "standalone"
}

# Init a primary  database container. With replicas.
function mysqli_config_with_replicas() {
    echo "Starting primary database..."
    docker run \
        --detach \
        --name "${DBHOST}" \
        --network "${NETWORK}" \
        -e MYSQL_DATABASE="${DBNAME}" \
        -e MYSQL_ROOT_PASSWORD="${DBPASS}" \
        -e MYSQL_USER="${DBUSER}" \
        -e MYSQL_PASSWORD="${DBPASS}" \
        -e DBHOST_DBREPLICA="${DBHOST_DBREPLICA}" \
        --tmpfs /var/lib/mysql:rw,noexec,nosuid,size=4096m \
        -v "${HOSTBASEDIR}/modules/docker-database/mysqli.d/primary/conf.d:/etc/mysql/conf.d" \
        -v "${HOSTBASEDIR}/modules/docker-database/mysqli.d/primary/docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d" \
        mysql:"${DBTAG}"

    # Wait few secs, before executing commands.
    # TODO: Find a better way to wait for the database to be ready.
    sleep 20

    mysqli_print_runtime_diagnostics "${DBHOST}" "primary"

    echo "Starting replica database..."
    docker run \
        --detach \
        --name "${DBHOST_DBREPLICA}" \
        --network "${NETWORK}" \
        -e MYSQL_DATABASE="${DBNAME}" \
        -e MYSQL_ROOT_PASSWORD="${DBPASS}" \
        -e MYSQL_USER="${DBUSER}" \
        -e MYSQL_PASSWORD="${DBPASS}" \
        -e DBHOST="${DBHOST}" \
        -e DBHOST_DBREPLICA="${DBHOST_DBREPLICA}" \
        -v "${HOSTBASEDIR}/modules/docker-database/mysqli.d/replica/conf.d:/etc/mysql/conf.d" \
        -v "${HOSTBASEDIR}/modules/docker-database/mysqli.d/replica/docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d" \
        --tmpfs /var/lib/mysql:rw,noexec,nosuid,size=4096m \
        mysql:"${DBTAG}"

    # Wait few secs, before executing commands.
    # TODO: Find a better way to wait for the database to be ready.
    sleep 20

    mysqli_print_runtime_diagnostics "${DBHOST_DBREPLICA}" "replica"
}
