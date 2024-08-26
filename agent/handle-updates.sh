#!/bin/bash

# Paths to the existing and rendered properties files
EXISTING_PROPERTIES="${CONFIG_HOME}/application.properties"
STATIC_PROPERTIES="${CONFIG_HOME}/application-static.properties"
DYNAMIC_PROPERTIES="${CONFIG_HOME}/application-dynamic.properties"
TEMP_PROPERTIES="${CONFIG_HOME}/application-merged.properties"

# Backup the existing properties file
cp "$EXISTING_PROPERTIES" "${EXISTING_PROPERTIES}.bak"

# Copy existing properties to a temporary file
cp "$EXISTING_PROPERTIES" "$TEMP_PROPERTIES"

# Function to merge properties from a file
merge_properties() {
  local file=$1
  while IFS= read -r line; do
    # Skip empty lines
    if [ -z "$line" ]; then
      continue
    fi

    # echo "Merging $line"

    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)

    # Use grep to check if the key exists and update it, otherwise add it
    if grep -q "^${key}=" "$TEMP_PROPERTIES"; then
      # Update the existing key with the new value
      sed -i "" "s|^${key}=.*|${key}=${value}|" "$TEMP_PROPERTIES"
    else
      # Add the new key-value pair if it doesn't exist
      echo "${key}=${value}" >> "$TEMP_PROPERTIES"
    fi
  done < "$file"
}

# Merge properties from both static and dynamic files
merge_properties "$STATIC_PROPERTIES"
merge_properties "$DYNAMIC_PROPERTIES"

# Check for differences between the merged file and the existing file
if ! diff "$TEMP_PROPERTIES" "$EXISTING_PROPERTIES" > /dev/null; then
  # If there are differences, copy the merged properties back to the existing file
  mv "$TEMP_PROPERTIES" "$EXISTING_PROPERTIES"
  # echo "Properties updated."

  # Trigger application refresh
  curl -X POST http://localhost:8080/actuator/refresh -d '{}' -H "Content-Type: application/json"
else
  # If no changes are detected, you can optionally delete the temporary file
  rm "$TEMP_PROPERTIES"
  # echo "No changes detected."
fi
