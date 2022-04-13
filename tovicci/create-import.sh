#!/bin/bash


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export IM_REPO_ROOT="../../.."

echo "${SCRIPT_DIR}/tovicci"
[ ! -d "${SCRIPT_DIR}/tovicci" ] && mkdir "${SCRIPT_DIR}/tovicci"
MACHINE_NAME=$(hostname -s)
AGENT_NAME="${MACHINE_NAME^^}"
echo "Which machine name are the Agents to use Tovicci installed on? [ENTER] to use ${MACHINE_NAME^^}"
read HOSTMACHINE


# SECURITY_AGENT='aiimi-security-agent_Security'
# OCR_AGENT='aiimi-ocr-agent_Ocr'
# MIGRATION_AGENT='aiimi-migration-agent_Migration'
# JOB_AGENT='aiimi-job-agent_Job'
# ENRICHMENT_AGENT='aiimi-enrichment-agent_Enrichment'
# CONTENT_AGENT='aiimi-content-agent_Content'
# SOURCE_AGENT='aiimi-source-agent_Source'

if ! [[ $HOSTMACHINE = '' ]] && ! [[ -z $HOSTMACHINE ]]; then
  AGENT_NAME="$HOSTMACHINE"
fi
# echo "AGENT_NAME = ${AGENT_NAME}"
# echo "HOSTMACHINE = ${HOSTMACHINE}"
# exit
SECURITY_AGENT="${AGENT_NAME}_Security"
OCR_AGENT="${AGENT_NAME}_Ocr"
MIGRATION_AGENT="${AGENT_NAME}_Migration"
JOB_AGENT="${AGENT_NAME}_Job"
ENRICHMENT_AGENT="${AGENT_NAME}_Enrichment"
CONTENT_AGENT="${AGENT_NAME}_Content"
SOURCE_AGENT="${AGENT_NAME}_Source"
echo "Applying to ${AGENT_NAME}..."

IMPORT_JSON="tovicci.json"
IMPORT_FOLDER="${SCRIPT_DIR}/tovicci"
IMPORTFILE="${IMPORT_FOLDER}/${IMPORT_JSON}"
cp "${SCRIPT_DIR}/tovicci.json" "${IMPORTFILE}"

export IMPORT_FOLDER="${IMPORT_FOLDER}"
export IMPORT_JSON="${IMPORT_JSON}"

# "AssignedTo": "TOVICCI-AZ-EL01_Security",
sed -i "s/TOVICCI-AZ-EL01_Security/${SECURITY_AGENT}/g" "${IMPORTFILE}"
sed -i "s/TOVICCI-AZ-EL01_Job/${JOB_AGENT}/g" "${IMPORTFILE}"
sed -i "s/TOVICCI-AZ-EL01_Ocr/${OCR_AGENT}/g" "${IMPORTFILE}"
sed -i "s/TOVICCI-AZ-EL01_Migration/${MIGRATION_AGENT}/g" "${IMPORTFILE}"
sed -i "s/TOVICCI-AZ-EL01_Enrichment/${ENRICHMENT_AGENT}/g" "${IMPORTFILE}"
sed -i "s/TOVICCI-AZ-EL01_Content/${CONTENT_AGENT}/g" "${IMPORTFILE}"
sed -i "s/TOVICCI-AZ-EL01_Source/${SOURCE_AGENT}/g" "${IMPORTFILE}"
sed -i "s/AIIMI-AZ-EL01_Source/${SOURCE_AGENT}/g" "${IMPORTFILE}"
FILE_SOURCE='\\AIIMI-AZ-EL02\Tovicci'
echo "What is the location of the Tovicci files? Leave blank to use ${FILE_SOURCE}."
read NEW_SOURCE

if [[ $NEW_SOURCE = '' ]] || [[ -z $NEW_SOURCE ]]; then
  NEW_SOURCE=$FILE_SOURCE
fi
# echo "${NEW_SOURCE}"
NEW_SOURCE=$(echo "$NEW_SOURCE" | sed "s/\\\\/\\\\\\\\\\\\\\\\/g")
# echo "${NEW_SOURCE}"
sed -i "s/E\:..Tovicci/${NEW_SOURCE}/gi" "${IMPORTFILE}"

echo "./tovicci/tovicci.json file can now be used by your IndexUtilities to import."
echo "InsightMaker.IndexUtilities.exe import --all PATH-TO-YOUR-NEW-FILE/tovicci.json"