# openshift-config
This is a script which has some configuration modules for a fresh and clean OpenShift installation. If you've been using the Single Node OpenShift installation, you need some persistent volumes and you need to make the internal registry able to store your images. 

This is what the script does right now:

- Creating 30 persistent volumens (locally on the OpenShift VM)
- Configuring the internal registry to be able to store images
- Installing some operators (namely gitops, serverless and pipelines) for demo purposes
- Setting up a 'ci' namespace with nexus and Gogs ready to use
- Setting up a htpasswd identity provider for 2 users

## Usage
In order to use this script for the following modules, you first need to be logged into OpenShift as a user with cluster-admin role. This is typically the `kubeadmin` user after a fresh installation.

- persistent-volumes
- registry
- operators
- create-users

The `ci` module does only need to have a user context (devel or developer).

The typical workflow after installing a OpenShift SNO from this page is:
- Create the OpenShift SNO
- `./config-snc.sh persistent-volumes`
- `./config-snc.sh registry`
- `./config-snc.sh create-users`



### persistent-volumes
```bash
$> ./config-snc.sh persistent-volumes -h 192.168.2.23
```

This creates 30 volumes within /mnt/pv-data on the SNO host at 192.168.2.23. Make sure, you're able to ssh into the machine. By default you should be able to do so without password, as the installer has your public key. 

```bash
$> ssh core@192.168.2.23
```

### registry
```bash
$> ./config-snc.sh registry 
```

This switches the internal registry to "Managed" and binds it to a PV called pv0001. For this module, you must be logged in as kube:admin in your cluster. 

### operators
```bash
$> ./config-snc.sh operators
```

This installs the gitops and the pipelines operators. Please make sure to be logged into the openshift instance as cluster-admin. And you already should have persistent volumes available.

### ci
```bash
$> ./config-snc.sh ci
```

This installs a Nexus and Gogs into a newly created namespace called ci. It also clones 3 repositories from github.com into Gogs. After that it prints out the access to both instances. By default, we are using

- Nexus: admin/admin123
- Gogs: gogs/gogs

### create-users
```bash
$> ./config-snc.sh create-users 
```
This adds a HTPasswd identity provider to the cluster with 2 users in it:
- admin/admin123 -> cluster-admin
- devel/devel -> normal user

You need to be logged into OpenShift with cluster-admin rights.
