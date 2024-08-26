#!/bin/bash

# Paths to the existing and rendered properties files
EXISTING_PROPERTIES="${CONFIG_HOME}/application.properties"
RENDERED_PROPERTIES="${CONFIG_HOME}/application-new.properties"
TEMP_PROPERTIES="${CONFIG_HOME}/application-merged.properties"

# Backup the existing properties file
cp "$EXISTING_PROPERTIES" "${EXISTING_PROPERTIES}.bak"

# Copy existing properties to a temporary file
cp "$EXISTING_PROPERTIES" "$TEMP_PROPERTIES"

# Define the list of characters
characters=(
  "Frodo" "Sam" "Gandalf" "Aragorn" "Legolas" "Gimli" "Boromir" "Sauron"
  "Saruman" "Gollum" "TomBom" "Denathor" "Elrond" "Galadriel" "Celeborn"
)

# Update the properties from the rendered file
while IFS= read -r line; do
  # Skip empty lines
  if [ -z "$line" ]; then
    continue
  fi

  echo "Merging $line"

  key=$(echo "$line" | cut -d'=' -f1)
  value=$(echo "$line" | cut -d'=' -f2-)

  # Check if the key starts with "app." - Only want LOTR characters added to those properties
  if [[ $key == app.* ]]; then
    random_character=${characters[$RANDOM % ${#characters[@]}]}
    value="${value}-${random_character}"
  fi

  # Use grep to check if the key exists and update it, otherwise add it
  if grep -q "^${key}=" "$TEMP_PROPERTIES"; then
    sed -i "" "s|^${key}=.*|${key}=${value}|" "$TEMP_PROPERTIES"
  else
    echo "$line" >> "$TEMP_PROPERTIES"
  fi
done < "$RENDERED_PROPERTIES"

# Check for differences
if ! diff "$TEMP_PROPERTIES" "$EXISTING_PROPERTIES" > /dev/null; then
  # Move the temporary file to the final properties file
  cp "$TEMP_PROPERTIES" "$EXISTING_PROPERTIES"
else
  # rm "$TEMP_PROPERTIES"
  echo "nothing"
fi
