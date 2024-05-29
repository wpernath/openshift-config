# openshift-config
This is a script which has some configuration modules for a fresh and clean OpenShift installation. If you've been using the Single Node OpenShift installation, you need some persistent volumes and you need to make the internal registry able to store your images. 

This is what the script does right now:

- It is setting up Kubevirt Hostpath Provisioner for storage
- Configuring the internal registry to be able to store images
- Installing some operators (namely gitops, serverless and pipelines, builds, postgresql and strimzi) for demo purposes
- Setting up a 'ci' namespace with nexus and Gitea ready to use
- Setting up a htpasswd identity provider for 2 users: admin and devel. admin is cluster-admin
- Setting up Google as SSO OAuth2 provider
- Configuring openshift console to show links and other resources for demo purposes
- Installing and configuring OpenShift ServiceMesh for demo
- Configure monitoring and user space monitoring 
- Installing and configuring Red Hat Developer Hub (based on backstage.io)

## Usage
In order to use this script, you first need to be logged into OpenShift as a user with cluster-admin role. This is typically the `kubeadmin` user after a fresh installation.

The following modules are available:
- ci
- console
- mesh
- rhdh
- monitoring
- oauth
- operators
- registry
- storage
- users


The `ci` module does only need to have a user context (devel or developer).

The typical workflow after installing a OpenShift SNO from this page is:
- Create the OpenShift SNO
- `./setup.sh storage` 
- `./setup.sh registry`
- `./setup.sh users`
- `./setup.sh console`
- `./setup.sh operators`

Be careful to NOT install storage if you've allready installed any other storage provider!

You could also let openshift-config decide what to install in your freshly installed OpenShift cluster by specifying an environment:
- sno: installs everything necessary (console, operators, storage, registry, users)
- crc: installs only necessary (console, operators, users)
- aws: installs only necessary (console, operators, users)
- all: like sno


### storage
```bash
$> ./setup.sh storage
```

This installs the CSI kubevirt hostpath provisioner into the target OpenShift installation. It also creates a StorageClass which will then be used for all PVs.

Please DO NOT install this if your OpenShift cluster allready contains a storage provider! 

### registry
```bash
$> ./setup.sh registry 
```

This switches the internal registry to "Managed" and binds it to a PV called pv0001. For this module, you must be logged in as kube:admin in your cluster. 

### operators
```bash
$> ./setup.sh operators
```

This installs several operators. Please make sure to be logged into the OpenShift instance as cluster-admin. And you already should have storage available.

### ci
```bash
$> ./setup.sh ci
```

This installs a Nexus and Gitea into a newly created namespace called ci. It also clones 3 repositories from github.com into Gitea. After that it prints out the access to both instances. By default, we are using

- Nexus: admin/admin123
- Gitea: gitea/openshift

### users
```bash
$> ./setup.sh users 
```
This adds a HTPasswd identity provider to the cluster with 2 users in it:
- admin/admin123 -> cluster-admin
- devel/devel -> normal user

You need to be logged into OpenShift with cluster-admin rights.

### console
```bash
$> ./setup.sh console
```
Installs some links to the openshift console and makes sure, developer view contains additional links to resources: pod, service, pvc, route

### mesh
```bash
$> ./setup.sh mesh
```
Installs Red Hat OpenShift ServiceMesh and adds the grumpycat application to the mesh.

This can be uninstalled by executing 
```bash
$> oc delete -k config/mesh
```

If you want to add other namespaces to the mesh, please edit the file `config/mesh/sm-members.yaml`. Please also note, that - in order to let the mesh inject the sidecar - you need to add the following annotation to the `Deployment` of a - well - deployment:

```yaml
spec:
  template:
    metadata:
      annotations:  
        sidecar.istio.io/inject: 'true'
```

## monitoring
```bash
$> ./setup.sh monitoring
```

Conifgures the monitoring provider of OpenShift so that all the data will be stored in provided storage. It also configures user monitoring. 
It also configures user monitoring. Please make sure you're adding service monitoring entries for special user services.

## oauth
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

## rhdh
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
