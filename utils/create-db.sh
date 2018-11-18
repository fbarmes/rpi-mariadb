#!/bin/sh

#-------------------------------------------------------------------------------
# global setup
#-------------------------------------------------------------------------------
INSTALL_DIR=$(dirname $(readlink -f $0));
SCRIPT_NAME=$(basename $(readlink -f $0));

#-------------------------------------------------------------------------------
# global vars with defaults
#-------------------------------------------------------------------------------
LOGIN_USER="root"
LOGIN_HOST="localhost"
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
VERBOSE=false
DRY_RUN=false

#-------------------------------------------------------------------------------
echo_vars() {
  echo "INSTALL_DIR=${INSTALL_DIR}"
  echo "SCRIPT_NAME=${SCRIPT_NAME}"
  echo "LOGIN_USER=${LOGIN_USER}"
  echo "LOGIN_HOST=${LOGIN_HOST}"
  echo "DB_NAME=${DB_NAME}"
  echo "DB_USER=${DB_USER}"
  echo "DB_PASSWORD=${DB_PASSWORD}"
}

#-------------------------------------------------------------------------------
# create_db function
#-------------------------------------------------------------------------------
create_db() {

  TMPFILE=$(mktemp)
  cat << EOF > ${TMPFILE}
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF

  if [ $VERBOSE = true ] ; then
    cat ${TMPFILE}
  fi


  #-- execute mysql
  echo "Create database [${DB_NAME}] with owner [${DB_USER}] and password [${DB_PASSWORD}]"

  if [ ! $DRY_RUN = true ] ; then
    echo "create db on ${LOGIN_HOST}"
    echo "login: ${LOGIN_USER}"
    mysql -h ${LOGIN_HOST} -u ${LOGIN_USER} -p < ${TMPFILE}
  fi

  rm ${TMPFILE}
}

#-------------------------------------------------------------------------------
# usage function
#-------------------------------------------------------------------------------
usage() {
  cat <<END_HELP
Usage: ${SCRIPT_NAME} <db_name> <db_user> <db_password>
    -U, --login-user <user>
    -H, --login-host <host>
    -h, --help Display this help
    -v, --verbose : display verbose output
    -d, --dry-run : do not execute script
END_HELP
}

#-------------------------------------------------------------------------------
# handle command line options
#-------------------------------------------------------------------------------
get_options() {
  OPTS_SHORT="U:,H:,h,v,d"
  OPTS_LONG="login-user:,login-host,help,verbose,dry-run"
  N_ARGS=3

  #-- run getopt
  GETOPT_RESULT=`getopt -o ${OPTS_SHORT} --long ${OPTS_LONG} -- $@`
  GETOPT_SUCCESS=$?

  #-- check getopt
  if [ $GETOPT_SUCCESS != 0 ]; then
    echo "Failed parsing options"
    usage
    exit 1
  fi

  #-- replace script argument with those returned by getopt
  eval set -- "$GETOPT_RESULT"

  #-- handle options
  while true ; do
    case "$1" in
        -U|--login-user) LOGIN_USER=$2;     shift 2;  ;;
        -H|--login-host) LOGIN_HOST=$2;     shift 2;  ;;
        -h|--help) usage; shift; exit 0; ;;
        -v|--verbose) VERBOSE=true;         shift;  ;;
        -d|--dry-run) DRY_RUN=true;         shift;  ;;
        --) shift; break; ;;
        *) echo "Invalid option $1"; exit 1; ;;
    esac
  done

  #-- check non-options parameters
  if [ $# -ne $N_ARGS ] ; then
    usage;
    exit 1
  fi

  #-- handle non-options parameters
  DB_NAME=$1
  DB_USER=$2
  DB_PASSWORD=$3
}

#-------------------------------------------------------------------------------
# main function
#-------------------------------------------------------------------------------
main() {
  get_options $@

  if [ $VERBOSE = true ] ; then
    echo_vars
  fi

  create_db
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
main $@
