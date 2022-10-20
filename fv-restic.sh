#! /bin/bash

## Variables
readonly RESTIC="restic" #Path to the restic 
readonly RESTIC_REPO="/path/to/restic-repo" # Path to the repository
readonly RESTIC_DIR="/path/to/.restic" # Path to the folder where all relevant files are saved (passwd.txt, include.txt, exclude.txt)
readonly NAME="PC-Home" # Name of the host.  The flag is omitted when empty.
readonly KEEP_PARAMS="--keep-daily 62 --keep-weekly 56 --keep-monthly 120 --keep-yearly 75" # Forget policies.
readonly LOG_FOLDER="/path/to/log_folder" # Path to the log folder (don't use / at the end).

readonly INCLUDE_FILE="$RESTIC_DIR/include.txt" # Path to the file containing list of backuped files and folders. The flag is omitted when empty.
readonly EXCLUDE_FILE="$RESTIC_DIR/exclude.txt" # Path to the file containing list of files and folders excluded from the backup. The flag is omitted when empty.
readonly PASSWD_FILE="$RESTIC_DIR/passwd.txt" # Path to the file containing password.

readonly CMD="$RESTIC -r $RESTIC_REPO -p $PASSWD_FILE"
readonly VERSION="0.1"

## Functions
help() {
  echo "This script is a shortcut to run most common restic commands."
  echo "-------------------------------------------------------------"
  echo
  echo "- All arguments are passed directly to restic, if an option is not recognized."
  echo "  It means all errors are raised by restic itself instead of this script."
  echo "  Restic is run with paths to both the password file and the repository"
  echo "  specified in this script for convenience."
  echo "- Stdout and stderr are saved to log files located in a folder defined"
  echo "  in this script (LOG_FOLDER variable)"
  echo
  echo "Syntax: fv-restic [-h|v|i|b|f|g|c]"
  echo "options:"
  echo "h     Print this Help."
  echo "v     Print version of this script."  
  echo "i     Initialize a new repository. Path"
  echo "b     Run backup."
  echo "f     Run forget and prune."
  echo "g     Run forget in dry-run mode (don't delete any data but show what actions'd"
  echo "      be performed). The output is not saved to any log file."
  echo "c     Run data integrity check (restic check --read-data)."
  echo
  echo "-c can be used with a parameter passed to restic --read-data-subset,"
  echo "   e.g. '$ fv-restic -c 10%' is run as restic check --read-data-subset=10%"
  echo
  echo "Usage:"
  echo "------"
  echo "- Initialize a repository. A path to the repository and a folder containing"
  echo "  the password file are sprecified in this script (RESTIC_REPO and RESTIC_DIR):"
  echo "  $ fv-restic.sh -i"
  echo "- Run backup using the repository and the password file defined in this script:"
  echo "  $ fv-restic.sh -b"
  echo "- Forget and prune the repo. The policy is defined in this script (KEEP_PARAMS):"
  echo "  $ fv-restic.sh -f"
  echo "- Run forget in dry-run mode. The policy is defined in this"
  echo "  script (KEEP_PARAMS):"
  echo "  $ fv-restic.sh -g"
  echo "- Check the integrity of the data in the repo. All data are loaded and checked:"  
  echo "  $ fv-restic.sh -c"
  echo "- Check integrity of the data. Only a subset is loaded and checked:"  
  echo "  $ fv-restic.sh -c 1/5"
  echo "  $ fv-restic.sh -c 10%"
  echo "- Use this script to run a repository integrity check using unknown command."
  echo "  $ fv-restic.sh check"
  echo "- Use this script to read snapshots in the repository."
  echo "  $ fv-restic.sh snapshots" 
}

timestamp() {
date "+%b %d %Y %T %Z"
}

finish_log() {
echo ""
echo "$(timestamp): fv-restic.sh finished"
echo "###############################################################################"
}

## Script
while getopts ":hvibfgc" arg; do
  case "${arg}" in
    h)
      help
      exit 0
      ;;    
    v)
      echo "$VERSION"
      exit 0
      ;;    
    i)
      echo "$CMD init"
      $CMD init
      exit 0
      ;;
    b)
      BACKUP_FLAGS=""
      if [ ! -z "$INCLUDE_FILE" ]; then
        BACKUP_FLAGS="$BACKUP_FLAGS--files-from $INCLUDE_FILE"
      fi
      if [ ! -z "$EXCLUDE_FILE" ]; then
        BACKUP_FLAGS="$BACKUP_FLAGS --exclude-file $EXCLUDE_FILE"
      fi
      if [ ! -z "$NAME" ]; then
        BACKUP_FLAGS="$BACKUP_FLAGS --host $NAME"
      fi
      
      MAIN_CMD="$CMD backup $BACKUP_FLAGS"
      LOG_FILE="$LOG_FOLDER/restic-backup.log"
      PROCESS="backup"
      ;;
    f)
      MAIN_CMD="$CMD forget $KEEP_PARAMS --prune"
      LOG_FILE="$LOG_FOLDER/restic-forget.log"
      PROCESS="forget and prune"
      ;;
    g)
      MAIN_CMD="$CMD forget $KEEP_PARAMS --dry-run"
      LOG_FILE="/dev/null"
      PROCESS="forget and prune"
      ;;
    c)
      MAIN_CMD="$CMD check --read-data"
      if [ ! -z "$2" ]; then
        MAIN_CMD="$MAIN_CMD-subset=$2"
      fi
      LOG_FILE="$LOG_FOLDER/restic-integrity.log"
      PROCESS="data integlity check"
      ;;
  esac
done

if [[ ! -d "$LOG_FOLDER" ]]; then
  mkdir -p $LOG_FOLDER
fi

(
if [ -z "$MAIN_CMD" ]; then
  echo "Options not recognized. All arguments passed to restic." >&2
  echo "$CMD $@"
  $CMD $@
  exit 0
fi

echo "###############################################################################"
echo "$(timestamp): fv-restic.sh started"
echo ""
$RESTIC version
echo ""

### Test if repo exists
echo "Checking access to the repository."
echo "----------------------------------"
echo "Time: $(timestamp)"
echo "$CMD snapshots"
$CMD snapshots
if [ "$?" -ne 0 ]; then
  echo "** Unable to detect the repository on path: $RESTIC_REPO **"
  finish_log
  exit 1
fi
echo ""

### Run command
echo "Starting $PROCESS"
echo "----------------"
echo "Time: $(timestamp)"
echo "$MAIN_CMD"
$MAIN_CMD
if [ "$?" -ne 0 ]; then
  echo "** Restic $PROCESS finished with non-zero exit code. **"
  finish_log
  exit 1
else
  echo "** Restic $PROCESS finished OK. **"
fi
echo ""

### Repository health check
echo "Checking health of the repository."
echo "----------------------------------"
echo "Time: $(timestamp)"
echo "$CMD check"
$CMD check
if [ "$?" -ne 0 ]; then
  echo "** Health check of the repository finished with non-zero exit code. **"
  finish_log
  exit 1
else
  echo "** Health check of the repository finished OK. **"
fi

finish_log
exit 0
) 2>&1 | tee -a $LOG_FILE
