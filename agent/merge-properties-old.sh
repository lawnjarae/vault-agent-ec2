#!/bin/bash

# Paths to the existing and rendered properties files
EXISTING_PROPERTIES="../src/main/resources/application.properties"
RENDERED_PROPERTIES="../src/main/resources/application-new.properties"
TEMP_PROPERTIES="../src/main/resources/application-merged.properties"

if ! test -f $TEMP_PROPERTIES; then
  touch $TEMP_PROPERTIES
fi

# Backup the existing properties file
cp "$EXISTING_PROPERTIES" "${EXISTING_PROPERTIES}.bak"

# Copy existing properties to a temporary file
cp "$EXISTING_PROPERTIES" "$TEMP_PROPERTIES"

# Update the properties from the rendered file
while IFS= read -r line; do
  key=$(echo "$line" | cut -d'=' -f1)
  # Use grep to check if the key exists and update it, otherwise add it
  if grep -q "^${key}=" "$TEMP_PROPERTIES"; then
    echo sed -i "s|^${key}=.*|${line}|" "$TEMP_PROPERTIES"
    echo ""
    sed -i "s|^${key}=.*|${line}|" "$TEMP_PROPERTIES"
  else
    echo "$line" >> "$TEMP_PROPERTIES"
  fi
done < "$RENDERED_PROPERTIES"

# Move the temporary file to the final properties file
mv "$TEMP_PROPERTIES" "$EXISTING_PROPERTIES"
