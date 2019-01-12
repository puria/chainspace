#!/usr/bin/env bash
set -e # Exit script if anything fails
set -u # unset variables cause an error
set -o pipefail # https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail
#set -x # for debugging each command

# This script takes input of a chainspace-network config file and the name of the node from that network that you want
# to generate and creates an output folder containing all the relevant files you need for that node.
# You can also pass "client-api" and it will generate a client api

CMD=$1
shift

ROOT_DIR="../.."
CHAINSPACE_APP_JAR=`ls ${ROOT_DIR}/chainspacecore/target/chainspace*-with-dependencies.jar`
BFT_JAR=`ls ${ROOT_DIR}/chainspacecore/lib/bft-smart*-DECODE.jar`
NODE_DIST_TEMPLATE="${ROOT_DIR}/contrib/core-tools/node-dist-template"

CONTRACT_DIR="../../chainspacecore/contracts"

function init-params {
    export NETWORK_CONFIG=$1
    export NODE_ID=$2
    export NETWORK_DIST_TARGET_DIR=$3
    export NODE_BUILD_DIR="${NETWORK_DIST_TARGET_DIR}/_node_build"
    export CLIENT_API_BUILD_DIR="${NETWORK_DIST_TARGET_DIR}/_client_api"
}

function show-params {
    echo "Node id: [${NODE_ID}]"
    echo "Network config [${NETWORK_CONFIG}]"
    echo "Target dir [${NETWORK_DIST_TARGET_DIR}]"
}

function remove_files_from_dir {
    DIR=$1
    FILES_TO_REMOVE=$2
    cd ${DIR}
    rm -rf ${FILES_TO_REMOVE}
    cd -
}

# -i doesn't work on osx so need to do it a long and boring way
function replace_template_parameter {
    TEMPLATE_FILE=$1
    PARAMETER=$2
    VALUE=$3
    if [[ "Darwin" == $(uname) ]]; then
        sed -e "s/${PARAMETER}/${VALUE}/g" ${TEMPLATE_FILE} >> ${TEMPLATE_FILE}.1
        rm ${TEMPLATE_FILE}
        cp ${TEMPLATE_FILE}.1 ${TEMPLATE_FILE}
        rm ${TEMPLATE_FILE}.1
    else
        sed -e "s/${PARAMETER}/${VALUE}/g" -i ${TEMPLATE_FILE}
    fi
}



function prepare-build-dirs {
    NETWORK_DIST_TARGET_DIR=$1
    NODE_BUILD_DIR="${NETWORK_DIST_TARGET_DIR}/_node_build"
    CLIENT_API_BUILD_DIR="${NETWORK_DIST_TARGET_DIR}/_client_api"

    echo "Cleaning and re-initialising [${NETWORK_DIST_TARGET_DIR}]..."

    rm -rf ${NETWORK_DIST_TARGET_DIR}
    mkdir -p ${NODE_BUILD_DIR}
    mkdir -p ${CLIENT_API_BUILD_DIR}

    cp ${CHAINSPACE_APP_JAR} ${NODE_BUILD_DIR}

    mkdir -p ${NODE_BUILD_DIR}/lib
    cp ${BFT_JAR} ${NODE_BUILD_DIR}/lib
    cp -r ${CONTRACT_DIR} ${NODE_BUILD_DIR}
    cp -r ${NODE_DIST_TEMPLATE}/* ${NODE_BUILD_DIR}


    cp -r ${NODE_BUILD_DIR}/* ${CLIENT_API_BUILD_DIR}
    remove_files_from_dir ${NODE_BUILD_DIR} "start_client_api.sh config/client-api"
    remove_files_from_dir ${CLIENT_API_BUILD_DIR} "config/node start_node.sh contracts"

    # cd ${NETWORK_DIST_TARGET_DIR} && tree && cd - # debugging
}

function clean-build-dirs {
    NETWORK_DIST_TARGET_DIR=$1
    NODE_BUILD_DIR="${NETWORK_DIST_TARGET_DIR}/_node_build"
    CLIENT_API_BUILD_DIR="${NETWORK_DIST_TARGET_DIR}/_client_api"

    rm -rf ${NODE_BUILD_DIR}
    rm -rf ${CLIENT_API_BUILD_DIR}

}
function generate-node-dist {
    echo "Generating a node distribution config:"
    init-params $@
    show-params
    echo ""

    CURRENT_REPLICA=$4 # Temporary until we read it from the config

    echo "Generating replica ${CURRENT_REPLICA}..."

    NODE_DIR=${NETWORK_DIST_TARGET_DIR}/${NODE_ID}


    mkdir -p ${NODE_DIR}
	cp -r ${NODE_BUILD_DIR}/* ${NODE_DIR}/
	replace_template_parameter ${NODE_DIR}/config/node/config.txt REPLICA_ID ${CURRENT_REPLICA}
	replace_template_parameter ${NODE_DIR}/start_node.sh __START_PORT__ 13${CURRENT_REPLICA}10
	chmod +x ${NODE_DIR}/start_node.sh
}

function generate-client-api-dist {
    echo "Generating a client-api distribution config:"
    init-params $@
    echo ""

    CLIENT_API="${NETWORK_DIST_TARGET_DIR}/client-api"
    mkdir -p ${CLIENT_API}


}





${CMD} $@