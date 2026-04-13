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

# LDAP module functions.

# This module defines the following env variables.
# LDAP module – osixia/openldap ersetzt larrycai/openldap.
# Das originale Image crasht auf modernen Kerneln (ch_calloc ... failed).
function docker-ldap_env() {
    env=(LDAPTESTURL)
    echo "${env[@]}"
}

function docker-ldap_check() {
    verify_modules docker
    verify_env NETWORK UUID
}

function docker-ldap_config() {
    LDAP=ldap"${UUID}"
    LDAPTESTURL="ldap://${LDAP}"
}

function docker-ldap_setup() {
    echo
    echo ">>> startsection Starting LDAP server <<<"
    echo "============================================================================"
    docker run \
        --detach \
        --name "${LDAP}" \
        --network "${NETWORK}" \
        -e LDAP_ORGANISATION="openstack" \
        -e LDAP_DOMAIN="openstack.org" \
        -e LDAP_ADMIN_PASSWORD="password" \
        --health-cmd="ldapsearch -x -H ldap://localhost -b 'dc=openstack,dc=org' -D 'cn=admin,dc=openstack,dc=org' -w password '(objectclass=*)' || exit 1" \
        --health-interval=5s \
        --health-timeout=5s \
        --health-retries=10 \
        osixia/openldap:1.5.0
    echo "LDAP: URL: ${LDAPTESTURL}"
    echo "============================================================================"
    echo ">>> stopsection <<<"
}