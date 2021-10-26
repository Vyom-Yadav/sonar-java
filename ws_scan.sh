#! /usr/bin/env bash

readonly URL="https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar"
readonly UNIFIED_AGENT_JAR="wss-unified-agent.jar"
readonly MD5_CHECKSUM="8E51FDC3C9EF7FCAE250737BD226C8F6"

get_ws_agent() {
  if [[ ! -f "${UNIFIED_AGENT_JAR}" ]]; then
    curl \
      --location \
      --remote-name \
      --remote-header-name \
      "${URL}"
  fi
  if [[ ! -f "${UNIFIED_AGENT_JAR}" ]]; then
    echo "Could not find downloaded Unified Agent" >&2
    exit 1
  fi

  # Verify JAR checksum
  local checksum="$(md5sum ${UNIFIED_AGENT_JAR} | cut --delimiter=" " --fields=1 | awk ' {print toupper($0) }')"
  if [[ "${checksum}" != "${MD5_CHECKSUM}" ]]; then
    echo -e "MD5 checksum mismatch.\nexpected: ${MD5_CHECKSUM}\ncomputed: ${checksum}" >&2
    exit 2
  fi

  # Verify JAR signature
  if ! jarsigner -verify "${UNIFIED_AGENT_JAR}"; then
    echo "Could not verify jar signature" >&2
    exit 3
  fi
}

scan() {
  export WS_PRODUCTNAME=$(maven_expression "project.name")
  export WS_PROJECTNAME="${WS_PRODUCTNAME} ${PROJECT_VERSION%.*}"
  echo "${WS_PRODUCTNAME} - ${WS_PROJECTNAME}"
  local jar_path="${CIRRUS_WORKING_DIR}/sonar-java-plugin/target/sonar-java-plugin-7.1.0-SNAPSHOT.jar"
  echo "${CIRRUS_WORKING_DIR}"
  ls
  echo "${jar_path}"
  mvn clean install
  java -jar wss-unified-agent.jar -c whitesource.properties -appPath "${jar_path}" -d "${CIRRUS_WORKING_DIR}"
}

get_ws_agent
scan
