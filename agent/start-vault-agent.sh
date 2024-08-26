#!/bin/bash

export CONFIG_HOME=/Users/jjarae/source/demo/cdl/moderizing-brownfield-apps/config
export NEW_PROPS_LOCATION=$CONFIG_HOME/application-new.properties

## Retrive role ID and secret ID
vault read -field=role_id auth/brownfield/role/brownfield-role/role-id > role-id.txt
vault write -f -field=secret_id auth/brownfield/role/brownfield-role/secret-id > secret-id.txt

vault agent -config vault-agent-config.hcl -log-level info
