#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
    echo "bye!"
}

main() {
	ACCOUNTS=()
	while IFS= read -r line; do
		clean_line=$(echo "$line" | tr -d '\r')
		ACCOUNTS+=("$clean_line")
	done < ./cloud_accounts

	for i in "${ACCOUNTS[@]}"; do
		API_KEY=$(echo "$i" | awk -F "," '{print $2}')
		if [ -z "$API_KEY" ]; then
		    echo
			echo "ERROR: please, add the API_KEYS in the cloud_accounts file."
			echo
			exit 1
		else
            SUFIX=$(openssl rand -hex 5)
			docker run -d --rm --name=delete-"$SUFIX" -e API_KEY="$API_KEY" delete-volumes:latest
		fi
	done
}

main "$@"