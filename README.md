# Wazuh Upgrade Script

This script automates the upgrade process for Wazuh components including the Wazuh Indexer, Server, Dashboard, and Agents.

## Usage

1. Clone or download the repository.
2. Ensure you meet the requirements listed in [requirements.txt](requeriments.txt).
3. Modify the script.sh file if necessary, providing required parameters.
4. Run the script: `./script.sh`.

## Requirements

Ensure the following dependencies are installed:

- curl
- rpm
- systemctl
- awk
- wazuh-manager
- wazuh-indexer
- wazuh-dashboard
- filebeat
- sudo (if not already installed)

For detailed instructions, refer to [requirements.txt](requirements.txt).

## License

This project is licensed under the [MIT License](LICENSE).

