#!/bin/bash
#
# This script uses runmqakm to create a KDB keystore (.kdb) for a SINGLE
# MQ queue manager. 
#

set -e

# Get the KDB password from Vault
export VAULT_ADDR="https://vault-cluster-public-vault-5440cd29.f3de9287.z1.hashicorp.cloud:8200"
export VAULT_TOKEN="$(cat /opt/vault/vault-agent/token-dir/vault-token-via-agent)"

KDB_PASSWORD=$(vault kv get -namespace=admin/ibm_mq -mount="secret" -field="kdb_password" "qmgrs/QM1")

# --- Configuration ---
# The name of the single queue manager you want to process.
QMGR_NAME="QM1"

# Base directory where Vault Agent writes the PEM files.
CERT_BASE_DIR="/var/mqm/qmgrs"

# --- Script Logic ---
echo "--- Starting certificate refresh for single QM: ${QMGR_NAME} ---"

# Set up variables for the target queue manager
qmgr_dir="${CERT_BASE_DIR}/${QMGR_NAME}/ssl/"
QMGR_NAME_LOWER=$(echo "${QMGR_NAME}" | tr '[:upper:]' '[:lower:]')

# Verify the certificate directory exists before proceeding
if [ ! -d "${qmgr_dir}" ]; then
    echo "Error: Directory for queue manager ${QMGR_NAME} not found at ${qmgr_dir}"
    exit 1
fi

# Define file paths
KEY_FILE="${qmgr_dir}privatekey.key"
CERT_FILE="${qmgr_dir}cert.pem"
CHAIN_FILE="${qmgr_dir}chain.pem"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BASE_KDB_FILE_NAME="key${TIMESTAMP}"
KDB_FILE="${qmgr_dir}${BASE_KDB_FILE_NAME}.kdb"
KDB_FILE_NO_EXT="${qmgr_dir}${BASE_KDB_FILE_NAME}"
TEMP_P12_FILE="${qmgr_dir}temp.p12"

# Define the label that MQ will use to identify the certificate.
CERT_LABEL="ibmwebspheremq${QMGR_NAME_LOWER}"

# 1. Create the KDB and stash file if they don't exist.
if [ ! -f "${KDB_FILE}" ]; then
    echo "KDB file not found. Creating new keystore and stash file..."
    runmqakm -keydb -create -db "${KDB_FILE}" -pw "${KDB_PASSWORD}" -type cms -stash
fi

# 2. Add the issuer (CA chain) certificates to the KDB.
echo "Adding CA chain certificates to KDB..."
runmqakm -cert -add -db "${KDB_FILE}" -pw "${KDB_PASSWORD}" -type cms -label "CARoot" -file "${CHAIN_FILE}" -trust enable || echo "CA already exists. Continuing..."

# 4. Combine the new key and cert into a temporary PKCS#12 file.
echo "Creating temporary PKCS#12 file..."
openssl pkcs12 -export -out "${TEMP_P12_FILE}" \
  -inkey "${KEY_FILE}" -in "${CERT_FILE}" \
  -certfile "${CHAIN_FILE}" \
  -passout pass:"${KDB_PASSWORD}" -name "${CERT_LABEL}"

# 5. Import the PKCS#12 file into the KDB.
echo "Importing new personal certificate into KDB..."
runmqakm -cert -import -file "${TEMP_P12_FILE}" -type pkcs12 -pw "${KDB_PASSWORD}" \
  -target "${KDB_FILE}" -target_pw "${KDB_PASSWORD}" -target_type cms

# 6. Clean up the temporary PKCS#12 file.
rm -f "${TEMP_P12_FILE}"

# 7. Signal the queue manager to refresh its SSL security context.
echo "Sending REFRESH SECURITY command to ${QMGR_NAME}..."
runmqsc "${QMGR_NAME}" <<EOF
ALTER QMGR SSLKEYR('${KDB_FILE_NO_EXT}')
ALTER QMGR CERTLABL('${CERT_LABEL}')
EOF

# Bounce the QM so all channels will have SSL refreshed.
echo "Restarting queue manager ${QMGR_NAME} to apply changes..."
endmqm -i "${QMGR_NAME}"
strmqm "${QMGR_NAME}"

echo "--- Successfully refreshed certificates for ${QMGR_NAME} ---"

exit 0

# 8. Clean up old KDB and STH files, keeping only the 5 newest sets.
echo "Cleaning up old keystore files..."
KEYSTORE_DIR="${qmgr_dir}"
MAX_FILES=5

# Count how many KDB files currently exist
COUNT=$(ls -1q "${KEYSTORE_DIR}"key*.kdb | wc -l)

if [ "$COUNT" -gt $MAX_FILES ]; then
    # Calculate how many files to delete
    NUM_TO_DELETE=$((COUNT - MAX_FILES))
    echo "Found ${COUNT} keystores. Deleting the ${NUM_TO_DELETE} oldest..."

    # List all .kdb files, sorted oldest to newest, then select the ones to delete
    FILES_TO_DELETE=$(ls -1tr "${KEYSTORE_DIR}"key*.kdb | head -n ${NUM_TO_DELETE})

    for file_path in $FILES_TO_DELETE; do
        # Derive the stash file path from the kdb file path
        stash_path="${file_path%.kdb}.sth"

        echo "Deleting: ${file_path}"
        rm -f "${file_path}"

        echo "Deleting: ${stash_path}"
        rm -f "${stash_path}"
    done
else
    echo "Found ${COUNT} keystores. No cleanup needed."
fi

echo "--- Cleanup complete ---"