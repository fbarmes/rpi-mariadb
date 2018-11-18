#!/bin/sh
set -e
#set -x

#-------------------------------------------------------------------------------
# setup environment
#-------------------------------------------------------------------------------
export MARIADB_USER="mysql"
export MARIADB_DATA_DIR="/data/mysql"
export MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"secret"}

export MARIADB_DB_NAME=${MARIADB_DB_NAME:-""}
export MARIADB_DB_USER=${MARIADB_DB_USER:-""}
export MARIADB_DB_PASSWORD=${MARIADB_DB_PASSWORD:-""}

#-------------------------------------------------------------------------------
setup_structure() {
  echo "-- Create structure"
  mkdir -p /run/mysqld
  mkdir -p ${MARIADB_DATA_DIR}
  chown -R mysql:mysql ${MARIADB_DATA_DIR}
  chown -R mysql:mysql /run/mysqld
}

#-------------------------------------------------------------------------------
install_database() {

  echo "-- install database"

  # check if ${MARIADB_DATA_DIR}/mysql

  /usr/bin/mysql_install_db         \
    --user=${MARIADB_USER}          \
    --datadir=${MARIADB_DATA_DIR}   \
    --skip-auth-anonymous-user > /dev/null
}

#-------------------------------------------------------------------------------
prepare_setup_script() {
  TMPFILE=$1;
  echo "-- create setup script in ${TMPFILE}"

  cat << EOF > ${TMPFILE}
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by '${MARIADB_ROOT_PASSWORD}' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' identified by '${MARIADB_ROOT_PASSWORD}' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("${MARIADB_ROOT_PASSWORD}") WHERE user='root';
DROP DATABASE test;
FLUSH PRIVILEGES;
EOF


  if [ "${MARIADB_DB_NAME}" != "" ] && [ "${MARIADB_DB_USER}" != "" ] ; then
    echo "-- will create database ${MARIADB_DB_NAME} and user ${MARIADB_DB_USER}"
    cat << EOF >> ${TMPFILE}
CREATE DATABASE IF NOT EXISTS ${MARIADB_DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON ${MARIADB_DB_NAME}.* TO '${MARIADB_DB_USER}'@'localhost' IDENTIFIED BY '${MARIADB_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MARIADB_DB_NAME}.* TO '${MARIADB_DB_USER}'@'%' IDENTIFIED BY '${MARIADB_DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF

  fi

}

#-------------------------------------------------------------------------------
setup_database() {
  TMPFILE=$1;
  echo "-- setup database"
  /usr/bin/mysqld --user=${MARIADB_USER} --datadir=${MARIADB_DATA_DIR} --bootstrap < ${TMPFILE}
}

#-------------------------------------------------------------------------------
function main() {

  #-- setup structure if not present
  if [ -d /run/mysqld ]; then
    echo "Skip create structure"
  else
    setup_structure
  fi

  #-- install and setup database if not present
  if [ -d ${MARIADB_DATA_DIR}/mysql ]; then
    echo "Skip install database"
  else
    #-- install database
    install_database

    #-- prepare setup script
    TMPFILE=$(mktemp)
    prepare_setup_script ${TMPFILE}

    #-- setup database
    setup_database ${TMPFILE}
    rm -f ${TMPFILE}
  fi


  #-- start mysql daemon
  echo "-- Start mysql daemon"
  /usr/bin/mysqld --user=${MARIADB_USER} --datadir=${MARIADB_DATA_DIR}
}


main
