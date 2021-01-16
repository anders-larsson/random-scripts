#!/bin/bash

set -o nounset
set -o errexit

source functions.shlib

# Local function for config to allow us to exit if parameter is mandatory and missing
get_config() {
  parameter=$1
  mandatory=${2:-false}
  config_value=$(config_get ${parameter})
  if [[ "${config_value}" == '__UNDEFINED__' ]] && [[ "${mandatory}" == "true" ]]; then
    echo "Mandatory parameter (${parameter}) not set."
    exit
  elif [[ "${config_value}" == '__UNDEFINED__' ]]; then
    echo ''
  else
    echo "${config_value}"
  fi
}

# No defaults, both optional. If GPG_RECIPIENTS undefined no GPG will be made
readonly GPG_RECIPIENT=$(get_config GPG_RECIPIENT)
readonly EXCLUDE_HOSTS=$(get_config EXCLUDE_HOSTS)

# Defaults included from config.cfg.defaults
readonly DATA_LOCATION=$(config_get DATA_LOCATION true)
readonly ARCHIVE_LOCATION=$(config_get ARCHIVE_LOCATION true)

readonly BACKUPPC_TARCREATE_BIN=$(config_get BACKUPPC_TARCREATE_BIN true)
readonly GZIP_BIN=$(config_get GZIP_BIN true)
readonly MD5SUM_BIN=$(config_get MD5SUM_BIN true)
readonly GPG_BIN=$(config_get GPG_BIN true)
readonly CAT_BIN=$(config_get CAT_BIN true)
readonly AWK_BIN=$(config_get AWK_BIN true)

do_archive() {
  local hostname=$1
  local data_directory=$2
  local date=$3
  local out_command=$4
  local archive_file="${ARCHIVE_LOCATION}/${hostname}-${date}.tar.gz.gpg"
  # Get latest full backup or if unavailable use '-1' (latest available)
  if [[ -f "${data_directory}/backups" ]]; then
    local latest_full_backup=$(${AWK_BIN} '/full/ { print $1 }' "${data_directory}/backups" | tail -1 || echo '-1')
  else
    latest_full_backup=-1
  fi

  ${BACKUPPC_TARCREATE_BIN} -t -h ${hostname} -n ${latest_full_backup} -s '*' . \
    | ${GZIP_BIN} \
    | ${out_command} ${archive_file}
  pushd ${ARCHIVE_LOCATION} &>/dev/null
  ${MD5SUM_BIN} "${archive_file##*/}" > "${archive_file}.md5sum"
  popd &>/dev/null
}

main() {
  date=$(date +%F)
  if [[ -n ${GPG_RECIPIENT} ]]; then
    local out_command="${GPG_BIN} --encrypt --batch --no-tty --compress-algo none --recipient ${GPG_RECIPIENT} --output"
  else
    local out_command="${CAT_BIN} >"
  fi

  for data_directory in ${DATA_LOCATION}; do
     local hostname=${data_directory##*/}
     echo "${EXCLUDE_HOSTS}" | grep -qv "${hostname}" || continue
     do_archive "${hostname}" "${data_directory}" "${date}" "${out_command}"
  done
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main
