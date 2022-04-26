# Elastic nodes and Kibana in Docker

## Prerequisites

### WSL2 - **Windows Subsystem for Linux**

WSL allows for a complete Linux distribution run as a sub-system. It integrates well into VSCode and is perfect for Dev work to done in an environment to which it will be run.

When given the option, the best OS to choose at the moment is Ubuntu 20.04 as the MS repo sources are most compatible with this.

To install WSL2 on your Windows machine, follow the [Microsoft Guidance](https://docs.microsoft.com/en-us/windows/wsl/install).

Once installed, you can open a Linux terminal by searching for WSL and clicking open. Handy to pin this to the taskbar.

### Docker

Docker is system that can virtualise a number of operating systems that will run programs in a chosen environment. These environments can be chosen from the extensive builds that can be found on [Docker Hub](https://hub.docker.com/). A good examplse are the [Dotnet images](https://hub.docker.com/_/microsoft-dotnet-core).

## Create Elastic

From the **elastic** path in a Ubuntu (WSL) terminal, the compose script will do it all for you:

```
./compose.sh
```

This script will ask you:
 - for the number of Elastic Nodes you want (defaults to 3)
 - the name of the Docker network to group these containers under (defaults to aiimi)

 It will create:
  - the certifcates
  - the nodes
  - a loadbalancer for the nodes (a single host:port combination is then possible)
  - kibana

This script will then inform you of where you can download the newly created certificates.

### Use your existing certificates

You can provide the path for your existing certificates with the **-c** parameter:
```
./compose.sh -c /mnt/c/InsightMaker/certs
```
Note that if they exist in windows, wsl should mount the windows system, like above. Docker will then mount this as the path for the certificates required by the containers.

This path will require a folder structure to match:
```
┬ ca ──────┬─ ca.crt
│          └─ ca.key
├ instance ┬─ ca.crt
│          └─ ca.key
├ elastic-certificates.p12
└ elastic-stack-ca.p12
```
The password protection would need to be the default **changeme**.

# Generate an import file for the Tovicci dataset

```
cd ./tovicci
./create-import.sh
```

You will be asked for
- the machine name where your Agents are to be installed. It will default to that of the machine you are on.
- the location of the EL02 shared drive. Might be wise to map it first, and when asked, supply ```f:\\Tovicci```

Copy you new json file, so it can be easily accessed by your **IndexUtilities.exe**, then run:
```
InsightMaker.IndexUtilities.exe import --all PATH-TO-YOUR-NEW-FILE/tovicci.json
```

This should then create all you need.

**NOTE** You find it easier to have first applied the index and mapping, and then install the BuiltinSecurity plugin.
```
InsightMaker.IndexUtilities.dll map -s
InsightMaker.IndexUtilities.dll initialise -afmsdp
InsightMaker.Security.BuiltinSecurityUtilities.dll initialise
```

# Spin-up a full AIE system in Docker

Perform any pre-requisites found in the [AIE Wiki](https://github.com/AiimiLtd/InsightMaker/wiki/Docker---Getting-Started) and ensure your Docker install is logged-in to Docker Hub with access to [AiimiLabs backend](https://hub.docker.com/repository/docker/aiimilabs/be), [AiimiLabs frontend](https://hub.docker.com/repository/docker/aiimilabs/fe) & [AiimiLabs elastic](https://hub.docker.com/repository/docker/aiimilabs/es).

To create a full InsightEngine system in Docker...

- from the Staging Branch

```
cd ./aie
./start.sh
```

- from a Release Tag (e.g. v1.0.0)

```
cd ./aie
./start.sh v1.0.0
```

This will create a full Network of all the Apps required for an operational system.