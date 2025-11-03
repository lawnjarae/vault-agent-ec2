#!/bin/bash
#
# This script is triggered by the Vault Agent after it renders new certificates.
# It iterates through all queue manager subdirectories, creates a KDB keystore
# for each using runmqakm, and signals each running queue manager to refresh.
#

set -e

# --- Configuration ---
# Base directory where Vault Agent writes the PEM files for each queue manager.
CERT_BASE_DIR="/etc/mqm/qmgrs"

# The password for all KDB files. The stash file will be created from this.
# IMPORTANT: Secure this script with appropriate file permissions (e.g., 700).
KDB_PASSWORD="YourStrongPasswordHere"

# --- Script Logic ---
echo "Starting MQ certificate refresh process..."

# Loop through each subdirectory in the base directory.
for qmgr_dir in ${CERT_BASE_DIR}/*/; do
    # Check if it is a directory
    if [ ! -d "${qmgr_dir}" ]; then
        continue
    fi

    QMGR_NAME=$(basename "${qmgr_dir}")
    QMGR_NAME_LOWER=$(echo "${QMGR_NAME}" | tr '[:upper:]' '[:lower:]')
    echo "----------------------------------------------------"
    echo "Processing Queue Manager: ${QMGR_NAME}"

    # Define file paths
    KEY_FILE="${qmgr_dir}key.pem"
    CERT_FILE="${qmgr_dir}cert.pem"
    CHAIN_FILE="${qmgr_dir}ca.pem"
    KDB_FILE="${qmgr_dir}key.kdb"
    TEMP_P12_FILE="${qmgr_dir}temp.p12"

    # Define the label that MQ will use to identify the certificate.
    CERT_LABEL="ibmwebspheremq${QMGR_NAME_LOWER}"

    # 1. Create the KDB and stash file if they don't exist. Note the "-type cms".
    if [ ! -f "${KDB_FILE}" ]; then
        echo "KDB file not found. Creating new keystore and stash file..."
        runmqakm -keydb -create -db "${KDB_FILE}" -pw "${KDB_PASSWORD}" -type cms -stash
    fi

    # 2. Add the issuer (CA chain) certificate to the KDB. Note the "-type cms".
    echo "Adding CA chain certificates to KDB..."
    runmqakm -cert -add -db "${KDB_FILE}" -pw "${KDB_PASSWORD}" -type cms -label "CARoot" -file "${CHAIN_FILE}" -trust enable || echo "CA already exists. Continuing..."

    # 3. Delete the old personal certificate from the KDB. Note the "-type cms".
    echo "Deleting old certificate with label ${CERT_LABEL}..."
    runmqakm -cert -delete -db "${KDB_FILE}" -pw "${KDB_PASSWORD}" -type cms -label "${CERT_LABEL}" || true

    # 4. Combine the new key and cert into a temporary PKCS#12 file.
    echo "Creating temporary PKCS#12 file..."
    openssl pkcs12 -export -out "${TEMP_P12_FILE}" \
      -inkey "${KEY_FILE}" -in "${CERT_FILE}" \
      -certfile "${CHAIN_FILE}" \
      -passout pass:"${KDB_PASSWORD}" -name "${CERT_LABEL}"

    # 5. Import the PKCS#12 file into the KDB. Note the "-target_type cms".
    echo "Importing new personal certificate into KDB..."
    runmqakm -cert -import -file "${TEMP_P12_FILE}" -type pkcs12 -pw "${KDB_PASSWORD}" \
      -target "${KDB_FILE}" -target_pw "${KDB_PASSWORD}" -target_type cms

    # 6. Clean up the temporary PKCS#12 file.
    rm -f "${TEMP_P12_FILE}"

    # 7. Signal the queue manager to refresh its SSL security context.
    echo "Sending REFRESH SECURITY command to ${QMGR_NAME}..."
    runmqsc "${QMGR_NAME}" <<< "REFRESH SECURITY TYPE(SSL)"

    echo "Successfully refreshed certificates for ${QMGR_NAME}."
done

echo "----------------------------------------------------"
echo "MQ certificate refresh process complete."