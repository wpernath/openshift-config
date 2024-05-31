# Module: rhdh
```bash
$> ./setup.sh rhdh
or
$> oc apply -k config/rhdh
```

Installs and configures Red Hat Developer Hub in a namespace called `rhdh` using the `Red Hat Developer Hub - Operator`. It configures the following plugins to be used with RHDH:
- GitHub Auth
- GitHub App
- GitHub SSO
- Kubernetes
- A sample software catalog based on https://github.com/wpernath/red-hat-developer-hub-software-templates/blob/main/templates.yaml

In order to make it your configuration, please copy both, the `example-backend-secret.env` and the `example-github-secret.env`, into `config/rhdh/backend-secret.env` and `config/rhdh/github-secret.env` and fill your tokens and secrets in there. 

To configure other plugins, please have a look at `config/rhdh/app-config-rhdh.yaml`. 
