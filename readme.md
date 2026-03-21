# Update all Proxmox LXC containers

_Currently in development_

Updates all LXC containers provisioned in your Proxmox enviroment.

## Usage

```bash
update-containers.sh [options]
```

### Options

- --exclude=[_container_id,container_id..._]
- --dry-run
- --reach=[_default: **all**_]
  - **all**:        Update all containers, start containers to update then shutdown
  - **running**:    Update only running containers
  - **stopped**:    Update only stopped containers