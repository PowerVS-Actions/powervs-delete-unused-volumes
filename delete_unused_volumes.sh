#!/bin/bash

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "bye!"
}

function check_dependencies() {

    DEPENDENCIES=(ibmcloud curl sh wget jq)
    check_connectivity
    for i in "${DEPENDENCIES[@]}"
    do
        if ! command -v "$i" &> /dev/null; then
            echo "$i could not be found, exiting!"
            exit
        fi
    done
}

function check_connectivity() {

    if ! curl --output /dev/null --silent --head --fail http://cloud.ibm.com; then
        echo
        echo "ERROR: please, check your internet connection."
        exit 1
    fi
}

function authenticate() {

    local APY_KEY="$1"
    if [ -z "$APY_KEY" ]; then
        echo "API KEY was not set."
        exit
    fi
    ibmcloud login --no-region --apikey "$APY_KEY" > /dev/null 2>&1
}

function delete_volumes() {

	CRNS=($(ibmcloud pi service-list --json | jq -r '.[] | "\(.CRN)"'))
	for crn in "${CRNS[@]}"; do
        set_powervs "$crn"
        delete_unused_volumes
	done
}

function delete_unused_volumes() {

    local JSON=/tmp/volumes-log.json

    > "$JSON"
    ibmcloud pi volumes --json | jq -r '.Payload.volumes[] | "\(.volumeID),\(.pvmInstanceIDs)"' >> $JSON

    while IFS= read -r line; do
        VOLUME=$(echo "$line" | awk -F ',' '{print $1}')
        VMS_ATTACHED=$(echo "$line" | awk -F ',' '{print $2}' | tr -d "\" \[ \]")
        if [ -z "$VMS_ATTACHED" ]; then
            echo "No VMs attached, deleting ..."
	    ibmcloud pi volume-delete "$VOLUME"
        fi
    done < "$JSON"
}

function set_powervs() {

    local CRN="$1"
    if [ -z "$CRN" ]; then
        echo "CRN was not set."
        exit
    fi
    ibmcloud pi st "$CRN"
}

main() {
	if [ -z "$API_KEY" ]; then
		echo
		echo "ERROR: please, add the API_KEYS in the cloud_accounts file."
		echo
		exit 1
	else
		check_dependencies
		check_connectivity
		authenticate "$API_KEY"
		delete_volumes
	fi
}

main "$@"