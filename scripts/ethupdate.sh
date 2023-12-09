#!/bin/bash
# author: Lefteris Karapetsas <lefteris@refu.co>
#
# A script to update the different ethereum repositories to latest develop
# Invoke from the root directory and make sure you have the arguments set as explained
# in the usage string.


# Get SCRIPT_DIR, the directory the script is located even if there are symlinks involved
FILE_SOURCE="${BASH_SOURCE[0]}"
# resolve $FILE_SOURCE until the file is no longer a symlink
while [ -h "$FILE_SOURCE" ]; do
	SCRIPT_DIR="$( cd -P "$( dirname "$FILE_SOURCE" )" && pwd )"
	FILE_SOURCE="$(readlink "$FILE_SOURCE")"
	# if $FILE_SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	[[ $FILE_SOURCE != /* ]] && FILE_SOURCE="$SCRIPT_DIR/$FILE_SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$FILE_SOURCE" )" && pwd )"

# Now that we got the directory, source some common functionality
source "${SCRIPT_DIR}/ethbuildcommon.sh"

ROOT_DIR=$(pwd)
NO_PUSH=0
UPSTREAM=upstream
ORIGIN=origin
REQUESTED_BRANCH=develop
REQUESTED_ARG=""
REQUESTED_PROJECT=""
REPO_URL=""
REPOS_MAP=("cpp-ethereum:https://github.com/ethereum/cpp-ethereum"
	   "cpp-ethereum-cmake:https://github.com/ethereum/cpp-ethereum-cmake"
	   "tests:https://github.com/ethereum/tests"
	   "webthree:https://github.com/ethereum/webthree"
	   "solidity:https://github.com/ethereum/solidity"
	   "alethzero:https://github.com/ethereum/alethzero"
	   "mix:https://github.com/ethereum/mix")

function get_repo_url() {
	if [[ $1 == "" ]]; then
		echo "ETHUPDATE - ERROR: get_repo_url() function called without an argument."
		exit 1
	fi
	for repo in "${REPOS_MAP[@]}" ; do
		KEY=${repo%%:*}
		if [[ $KEY =~ $1 ]]; then
			REPO_URL=${repo#*:}
			break
		fi
	done
	if [[ $REPO_URL == "" ]]; then
		echo "ETHUPDATE - ERROR: Requested url of unknown repo: ${1}."
		exit 1
	fi
}

function print_help {
	echo "Usage: ethupdate.sh [options]"
	echo "Arguments:"
	echo "    --help                    Will print this help message."
	echo "${PROJECTS_HELP}"
	echo "    --branch NAME             Will update to the specified branch. Default is ${REQUESTED_BRANCH}."
	echo "    --origin NAME             Will send the updates back to origin NAME if specified."
	echo "    --upstream NAME           The name of the remote to pull from. Default is ${UPSTREAM}."
	echo "    --no-push                 Don't push anything back to origin."
}

for arg in ${@:1}
do
	if [[ ${REQUESTED_ARG} != "" ]]; then
		case $REQUESTED_ARG in
			"origin")
				ORIGIN=$arg
				;;
			"upstream")
				UPSTREAM=$arg
				;;
			"branch")
				REQUESTED_BRANCH=$arg
				;;
			"project")
				set_repositories "ETHUPDATE" $arg
				;;
			*)
				echo "ETHUPDATE - ERROR: Unrecognized argument \"$arg\".";
				print_help
				exit 1
		esac
		REQUESTED_ARG=""
		continue
	fi

	if [[ $arg == "--help" ]]; then
		print_help
		exit 1
	fi

	if [[ $arg == "--branch" ]]; then
		REQUESTED_ARG="branch"
		continue
	fi

	if [[ $arg == "--project" ]]; then
		REQUESTED_ARG="project"
		continue
	fi

	if [[ $arg == "--origin" ]]; then
		REQUESTED_ARG="origin"
		continue
	fi

	if [[ $arg == "--upstream" ]]; then
		REQUESTED_ARG="upstream"
		continue
	fi

	if [[ $arg == "--no-push" ]]; then
		NO_PUSH=1
		continue
	fi

	echo "ETHUPDATE - ERROR: Unrecognized argument \"$arg\".";
	print_help
	exit 1
done

if [[ ${REQUESTED_ARG} != "" ]]; then
	echo "ETHUPDATE - ERROR: Expected value for the \"${REQUESTED_ARG}\" argument";
	exit 1
fi

for repository in "${CLONE_REPOSITORIES[@]}"
do
	CLONED_THE_REPO=0
	cd $repository >/dev/null 2>/dev/null
	if [[ $? -ne 0 ]]; then
		if [[ $REQUESTED_PROJECT == "" ]]; then
			echo "ETHUPDATE - INFO: Skipping ${repository} because directory does not exit";
			cd $ROOT_DIR
			continue
		else
			echo "ETHUPDATE - INFO: Repository ${repository} for requested project ${REQUESTED_PROJECT} did not exist. Cloning ..."
			get_repo_url $repository
			git clone $REPO_URL
			CLONED_THE_REPO=1
			cd $repository >/dev/null 2>/dev/null
		fi
	fi
	BRANCH="$(git symbolic-ref HEAD 2>/dev/null)" ||
		BRANCH="(unnamed branch)"     # detached HEAD
	BRANCH=${BRANCH##refs/heads/}
	if [[ $BRANCH != $REQUESTED_BRANCH ]]; then
		echo "ETHUPDATE - WARNING: Not updating ${repository} because it's not in the ${REQUESTED_BRANCH} branch"
		cd $ROOT_DIR
		continue
	fi

	# Pull changes from what the user set as the upstream repository, unless it's just been cloned
	if [[ $CLONED_THE_REPO -eq 0 ]]; then
		git pull $UPSTREAM $REQUESTED_BRANCH
	else
		# if just cloned, make a local branch tracking the origin's requested branch
		git fetch origin
		if [[ $BRANCH != $REQUESTED_BRANCH ]]; then
			git checkout --track -b $REQUESTED_BRANCH origin/$REQUESTED_BRANCH
		fi
	fi

	if [[ $? -ne 0 ]]; then
		echo "ETHUPDATE - ERROR: Pulling changes for repository ${repository} from ${UPSTREAM} into the ${REQUESTED_BRANCH} branch failed."
		cd $ROOT_DIR
		continue
	fi
	# If upstream and origin are not the same, push the changes back to origin and no push has not been asked
	if [[ $NO_PUSH -eq 0 && $UPSTREAM != $ORIGIN ]]; then
		git push $ORIGIN $REQUESTED_BRANCH
		if [[ $? -ne 0 ]]; then
			echo "ETHUPDATE - ERROR: Could not update origin ${ORIGIN} of repository ${repository} for the ${REQUESTED_BRANCH}."
			cd $ROOT_DIR
			continue
		fi
	fi
	echo "ETHUPDATE - INFO: ${repository} succesfully updated!"
	cd $ROOT_DIR
done
