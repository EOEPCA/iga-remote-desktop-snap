# SNAP via Remote Desktop

This interactive application provides a remote desktop with SNAP via JupyterHub.

It relies on the [jupyter-remote-desktop-proxy](https://github.com/jupyterhub/jupyter-remote-desktop-proxy)

## ApplicationHubConfiguration

Below an example of configuration in the ApplicationHub:

```yaml
- id: profile_iga_remote_desktop_snap
  groups: 
  - group-1
  definition:
    display_name: SNAP
    slug: iga_remote_desktop_snap
    default: False
    kubespawner_override:
      cpu_limit: 1
      mem_limit: 4G
      image:  eoepca/iga-remote-desktop_snap
  default_url: "desktop"
  node_selector: 
    k8s.provider.com/pool-name: node-pool-a
```
