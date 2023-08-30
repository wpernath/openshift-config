# openshift-config
This is a script which has some configuration modules for a fresh and clean OpenShift installation. If you've been using the Single Node OpenShift installation, you need some persistent volumes and you need to make the internal registry able to store your images. 

This is what the script does right now:

- It is setting up Kubevirt Hostpath Provisioner for storage
- Configuring the internal registry to be able to store images
- Installing some operators (namely gitops, serverless and pipelines, postgresql and strimzi) for demo purposes
- Setting up a 'ci' namespace with nexus and Gitea ready to use
- Setting up a htpasswd identity provider for 2 users: admin and devel. admin is cluster-admin
- Configuring openshift console to show links and other resources for demo purposes
- Installing and configuring OpenShift ServiceMesh for demo

## Usage
In order to use this script, you first need to be logged into OpenShift as a user with cluster-admin role. This is typically the `kubeadmin` user after a fresh installation.

The following modules are available:
- console
- storage
- registry
- operators
- ci
- users
- mesh

The `ci` module does only need to have a user context (devel or developer).

The typical workflow after installing a OpenShift SNO from this page is:
- Create the OpenShift SNO
- `./setup.sh storage`
- `./setup.sh registry`
- `./setup.sh users`


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
$> oc apply -k config/mesh
````
``