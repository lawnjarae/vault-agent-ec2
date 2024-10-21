{{ with secret "database/creds/my-role" }}
export POSTGRES_USERNAME="{{ .Data.username }}"
export POSTGRES_PASSWORD="{{ .Data.password }}"
{{ end }}



https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent/template#global-configurations
lease_renewal_threshold

Can't tell if static_secret_render_interval actually renders the template again or not


Paths in vault agent config are going to be relative to where the agent is run from.
vault agent -config vault-agent-config.hcl should be run from the agent folder.


docker run --name postgres -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgrespassword -d postgres
docker run --name minio -p 9000:9000 -p 9001:9001 -d minio/minio -v minio_data:/Users/jjarae/source/terraform/minio-data server /data --console-address ":9001"

vault write auth/brownfield/login role_id="6985732f-86a9-04c8-3cae-2fc270e1f838" secret_id="6cdc7e0a-ec9c-07dc-9773-fd4f91a286d4"

Will need a CONFIG_HOME env var set so that we can read the external application.properties file.
spring.config.import=file:${CONFIG_HOME:/vault/secrets}/database.properties

java -jar moderizing-brownfield-apps-0.0.1-SNAPSHOT.jar --spring.config.location=${CONFIG_HOME}/application.properties --server.port=8080


export CONFIG_HOME=$CONFIG_HOME
export VAULT_ADDR=$VAULT_ADDR
export VAULT_NAMESPACE=$VAULT_NAMESPACE

doormat login && eval $(doormat aws export --account aws_justin.jarae_test)