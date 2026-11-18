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

## Container Image Strategy & Availability

This project publishes container images to GitHub Container Registry (GHCR) following a clear and deterministic tagging strategy aligned with the Git branching and release model.

### Image Registry

Images are published to:

```
ghcr.io/<repository-owner>/iga-remote-desktop-snap
```

The registry owner corresponds to the GitHub repository owner (user or organization).

Images are built with Docker Buildx, scanned as a Docker archive, and published
with Skopeo. Pull requests run the same build and scan but cannot publish.

### Tagging Strategy

The image tag is derived automatically from the Git reference that triggered the build:


| Git reference    | Image tag    | Purpose                            |
| ---------------- | ------------ | ---------------------------------- |
| `develop` branch | `latest-dev` | Development and integration builds |
| `main` branch    | `latest`     | Stable branch builds               |
| Git tag `vX.Y.Z` | `X.Y.Z`      | Immutable release builds           |

## SNAP versions

| Image tag    | SNAP version  |
| ------------ | ------------- |
|    1.0.0     |     9.0       |
|    1.1.x     |    12.0       |

## Image maintenance and validation

The Dockerfile pins the remote-desktop parent to release `1.2.0` and declares
the SNAP major/minor version explicitly. Update these versions in reviewed pull
requests; require a successful image build and SNAP desktop smoke test before
release. A Fedora migration needs separate SNAP, Java, and desktop compatibility
evidence.

Pull requests build and scan the image without publishing it, then retain an
SPDX SBOM for seven days. Trivy HIGH/CRITICAL findings are report-only and are
not a security certification. Monthly Dependabot updates check Docker base
images and GitHub Actions.
