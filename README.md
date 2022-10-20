# fv-restic

fv-restic.sh is a shell script making [restic](https://github.com/vrbacky/fv-restic) backup tool easier to use. All basic commands used to back up files, check data integrity and remove snaphots according to a provided policy are included.

## Prerequisites
- [restic](https://restic.net)

## Installation
- Clone the repo
`git clone https://github.com/vrbacky/fv-restic`

## Usage
- Restic is run with paths to both a password file and a repository specified in the script for convenience.
- All arguments are passed directly to restic, if an option is not recognized.
- Stdout and stderr are saved to log files located in a folder defined in this script (LOG_FOLDER variable).

### Examples
- Initialize a repository. A path to the repository and a folder containing

`$ fv-restic.sh -i`

- Run backup using the repository and the password file defined in this script

`$ fv-restic.sh -b`

- Forget and prune the repo. The policy is defined in this script (KEEP_PARAMS):

`$ fv-restic.sh -f`

- Run forget in dry-run mode. The policy is defined in this script (KEEP_PARAMS):

`$ fv-restic.sh -g`

- Check the integrity of the data in the repo. All data are loaded and checked:

`$ fv-restic.sh -c`

- Check integrity of the data. Only a subset is loaded and checked:

`$ fv-restic.sh -c 1/5`

`$ fv-restic.sh -c 10%`

- Use this script to run a repository integrity check using unknown command.

`$ fv-restic.sh check`

- Use this script to read snapshots in the repository."

`$ fv-restic.sh snapshots`

## Author
- **Filip VRBACKY**

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
