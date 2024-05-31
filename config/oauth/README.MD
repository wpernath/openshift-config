# Module: oauth
```bash
$> ./setup.sh oauth
```

Configures an SSO provider (namely Google). Please make sure to first go to [Google Console](https://console.developers.google.com/apis/credentials) and register a new OAuth2 client. Then take the generated ClientID and Client Secret and create a new file `config/oauth/client-secret.env` based on the file 
`config/oauth/example-client-secret.env`. 

Then you're able to log into OpenShift via your SSO provider's user/pwd combination. If you've logged in once, you should also make sure that your
newly created user has all required roles associated with it. In my case, I am calling the following 

```bash 
$> oc adm policy add-cluster-role-to-user cluster-admin "wpernath@redhat.com"
```
