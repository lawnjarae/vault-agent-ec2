# DDR Demo: Vault - Modernizing Brownfield Applications with Vault Agents

## Demo Prerequisites

## Demo Provision Time

This demo should take about **5 minutes** to provision.

## Field Resources

### The Pain

Legacy brownfield applications often struggle with managing secrets securely and efficiently. Secrets like database credentials and API keys are frequently hardcoded into application code or scattered across various configurations, making them difficult to manage and prone to exposure. The lack of a centralized secrets management system adds complexity, requiring manual updates and rotations that often necessitate significant downtime. These challenges not only hinder operational efficiency but also increase security risks, making it difficult to adapt to modern compliance and regulatory requirements.

### The Solution

HashiCorp Vault, combined with Vault Agent, provides an elegant solution for managing secrets in legacy brownfield applications. By centralizing secrets into a single source of truth, Vault eliminates the risks of hardcoded credentials and scattered configurations. Vault Agent automates the delivery and rotation of secrets, seamlessly injecting them into configuration files or environment variables without requiring application downtime or manual intervention. This ensures that secrets are always current and secure, while dynamic secret generation enables frequent rotations to minimize exposure. With robust auditing and fine-grained access controls, Vault enhances both security and compliance, all while reducing operational overhead and extending the lifespan of legacy systems.

### Demo Recording

COMING SOON!

### Slide Deck

You can use this [slide deck](https://docs.google.com/presentation/d/1iTd1rUEBsnM779LSBlhxTDybbtXbUPsq8X30lobNw3U/edit?usp=sharing) as the presentation portion of your demo. Feel free to make a copy of the deck to customize the deck or add/remove any slides.

### Additional Content

- [Vault Agent](https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent)
- [Auto-Auth](https://developer.hashicorp.com/vault/docs/agent-and-proxy/autoauth)
- [AppRole](https://developer.hashicorp.com/vault/docs/auth/approle)
- [Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases)
- [KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
- [Vault Agent](https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent)

### Architecture

[Sequence Diagram](https://github.com/lawnjarae/modernizing-brownfield-applications/blob/72d822095b9ad88e6e063f74ac6dd3af902c8605/brownfield-approle.png)

## Run The Demo

### Talk Track and Instructions

1. Introduction
   - Talk Track: "Welcome everyone. Today we're going to be going over how you can modernize your brownfield applications. Legacy brownfield applications often struggle with managing secrets securely and efficiently. Secrets like database credentials and API keys are frequently hardcoded into application code or scattered across various configurations, making them difficult to manage and prone to exposure. The lack of a centralized secrets management system adds complexity, requiring manual updates and rotations that often necessitate significant downtime. These challenges not only hinder operational efficiency but also increase security risks, making it difficult to adapt to modern compliance and regulatory requirements."
   - Talk Track: "When we look at how brownfield applications can be modernized to utilize Vault as a secrets management solution, we need to understand that it might not be possible to make those applications Vault aware. Instead, we should be asking how can we seemlessly replace the current static secret location with a secret stored in Vault?"
   - Talk Track: "Vault can integrate with several patterns to accomplish this goal, but today, we're going to look at using the Vault Agent to retrieve secrets and store them in a SpringBoot [`application.properties`](apps/brownfield-app/config/application.properties) file. We'll also look at how we can perform hot reloads when secrets are updated."

2. What's the application look like today?
   - *Action: open the `application.properties` file.*
      - In the no-code module repo for this demo, open and show the [`application.properties`](apps/brownfield-app/config/application.properties) file.
   - Talk Track: "The environment that we're going to look at today is very common. We have a Java SpringBoot application that has some static secrets stored in the [`application.properties`](apps/brownfield-app/config/application.properties) file. This application also needs to talk to a database, so we also have our database credentials stored as `spring.datasource` values in the `application.properties` file."
   - Talk Track: "For ease of demoing what these values look like, the application is also hosting a webpage."
   - *Action: Pull up the webpage that does not rotate secrets.*
      - In the no-code provisioned workspace **Overview**, click on **Outputs**.
      - Open the **`app_without_agent_url`** output.
   - Talk Track: "As expected, these values are statically defined and as the page refreshes, the values won't change."
   - Talk Track: "What it takes to updates these secrets will vary from organization to organization, but often times the secret values would be updated once a year at best, would require manual intervention, and application downtime. If one application goes down, it's likely that the team that owns that application would need to coordinate with other downstream systems. This entire process becomes cumbersome and brittle leading teams to leave their secrets unchanged for far longer than they should be. The longer a secret goes unchanged, the more risk there is of that secret being used by an attacker."

3. So how can we make this better?
   - Talk Track: "We're going to leverage the Vault Agent to simplify this entire process. The Vault Agent provides a more scalable and simpler way for applications to integrate with Vault, by providing the ability to render templates containing the secrets required by your application, without requiring changes to your application."
   - Talk Track: "Vault Agent provides a number of excellent features that make it the perfect fit for working with brownfield applications."
      - "The first feature being auto-auth. This feature allows you to automatically authenticate to Vault and manage token renewal for accessing secrets, automating the authentication process."
      - "The second feature is an API proxy, which acts as a proxy for Vault's API, allowing applications to communicate with Vault through the agent, optionally using the auto-auth token."
      - "Third we have caching. This feature provides client-side caching of responses, including newly created tokens and leased secrets, reducing load on Vault and improving performance."
      - "The fourth feature to callout is templating. This allows you to render user-supplied templates using tokens generated by auto-auth, facilitating the integration of secrets into application configurations."
      - "You can also make use of something called process supervisor mode. This mode runs child processes with Vault secrets injected as environment variables, ensuring secure and dynamic secret management."
      - "Lastly, we have the `exec` block which is the swiss army knife of Vault Agent. The `exec` block allows you to run commands on the system after a new template is rendered. So after a secret has been rotated, you can have the `exec` block run a command or script to perform any additional operations."
   - Talk Track: "In the simplest terms, Vault Agent allows you to determine how you'd like to authenticate to Vault, which secrets you'd like to retrieve, and how you want those secrets rendered. It    does this while also managing the token and lease lifecycle so you don't have to."

4. Examining the Vault Agent config and how our application will receive updated secrets
   - *Action: Open up the Vault Agent config and walk through the various sections.*
      - Open the [Vault Agent configuration](https://github.com/lawnjarae/modernizing-brownfield-applications/blob/main/apps/agent/vault-agent-config-approle.hcl).
   - Talk Track: "Take a look at the agent configuration. Typically one of the first configuration options you will see in the Vault Agent is `auto_auth` where we will define our authentication method and also configure where our Vault token will be stored. In this specific demo we use Approle, which is a very common authentication method we see used with legacy applications. Vault agent can use a number of authentication methods for auto auth. Outside of AppRole, you can use AWS, Azure, GCP, TLS Certificates, Kubernetes, etc."
   - Talk Track: "The next configuration option you will typically see is how we define a template with the `template` block. Templates will typically be a separate configuration file where we define the secret backend we will be using, file rendering, and configuration options for that secret. We will have two templates used in this agent configuration, one will be for the static secret (KVv2) and one will be for the Postgres username/password.
      > **NOTE**: We have a good amount of Vault Agent Template examples in our documentation if the customer would like to see an example of templating for a secret engine not used in this demo.
   - Talk Track: "And the last configuration option we use in this demo is the optional `exec`. This allows Vault agent to run a child process to run commands, execute scripts, or inject secrets as environment variables. `exec` is a very useful feature especially in legacy environments where you may need some custom actions to properly consume a secret."
   - Talk Track: "So let's walk through the flow of what's going to happen with our application now that we're using Vault Agent to hot reload our secrets."
   - *Action: Walk through the [sequence diagram](https://github.com/lawnjarae/modernizing-brownfield-applications/blob/72d822095b9ad88e6e063f74ac6dd3af902c8605/brownfield-approle.png)*
      - Talk through the diagram top to bottom, explaining each arrow.
   - Talk Track: "The crucial step, from our applications point of view, is that it receives a message to its Actuator refresh endpoint telling it to reload beans marked with the @RefreshScope annotation. When that happens, Spring will refresh the configuration to reflect the new changes without the need to restart the JVM."

5. Seeing it in action
   - Talk Track: "Now let's look at this entire workflow in action."
   - *Action: Pull up the webpage that rotates secrets.*
      - In the no-code provisioned workspace **Overview**, click on **Outputs**.
      - Open the **`app_with_agent_url`** output.
      - The webpage will refresh every 5 seconds
      - Static secrets will update every 15 seconds
      - Dynamic secrets will update every 45 seconds
   - Talk Track: "We can see that our secrets are being updated without having to restart our application."

6. Conclusion
   - Talk Track: "By configuring the Vault Agent to refresh our static and dynamic secrets and allowing our brownfield applications to hot reload those secrets, we're able to dramatically improve our security posture by eliminating long-lived credentials. Additionally, we're effectively eliminating the need for the complicated, error-prone process of manually performing updates to these secrets during a scheduled outage that would involve many teams."

## Cleanup

To help manage cloud costs effectively, we prefer you queue a destroy run to clean up the resources from each demo. You can do so by queuing a destroy run in the no-code provisioned workspace of this demo:

- In your no-code provisioned workspace, navigate to the **Settings** tab on the left-side navigation panel
- Click on **Destruction and Deletion**
- Scroll down and click the red box labeled **Queue destroy plan**
- Enter the name of the workspace and confirm the destroy

You can keep the workspace for each demo module in your `hc-<username>` project, however, we suggest you destroy the resources associated with each module when you're done using it and reprovision when needed.
