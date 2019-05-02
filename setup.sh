#
# script to help deploy webapps
#
# essentially a type of 'make' file.
#
# the project can be set up to run in Prod, Dev, and Pycharm environments with 'configure'
# the project can be customized for any of the UCB deployments with 'deploy'
# individual webapps can be enabled and disabled
#
# this bash script does the following:
#
# 1. 'configure' builds a django app within the repo directory in the usual way (using manage.py)
# 2. 'deploy':
#     a. copies and configures the code for either 'default' or for one of the 5 UCB deployments
#     b. "npm builds" the needed js components
#     c. if running on a UCB server (which is detected automatically), copies the code in the runtime directory
# 3. other maintainance functions: 'updatejs' just rebuilds the webpack, 'disable' or 'enable' individual webapps
#

# exit on errors...
# TODO: uncomment this someday when the script really can be expected to run to completion without errors
# set -e

PYTHON=python

function buildjs()
{
    # TODO: fix this hack to make the small amount of js work for all the webapps
    export TENANT="$TENANT"
    perl -i -pe 's/..\/..\/suggest/\/$ENV{TENANT}\/suggest/' client_modules/js/PublicSearch.js

    npm install
    npm build
    ./node_modules/.bin/webpack
    # disable this for now, until we address the errors it generates on the "legacy" servers
    #./node_modules/.bin/eslint client_modules/js/app.js
}

function deploy()
{
    $PYTHON manage.py syncdb --noinput
    # rebuild the js libraries in case the javascript has been tweaked
    buildjs $1
    $PYTHON manage.py collectstatic --noinput
    # update the version file
    $PYTHON common/setversion.py
    # if this is running on a dev or prod system (evidenced by the presence of web-accessible
    # deployment directories, i.e. /var/www/*), then copy the needed files there
    # nb: the config directory and cspace_django_site/main.cfg are not overwritten!
    if [[ -e /var/www/$1 ]]; then
        # copy the built files to the runtime directory, but leave the config files as they are
        rsync -av --delete --exclude node_modules --exclude .git --exclude .gitignore --exclude config --exclude main.cfg . /var/www/$1
    fi

    # put things back the way they were...
    if [[ $VERSION != "" ]]; then
        git checkout master
        git branch -d deploy
    fi
}

function check_version()
{
    if [[ $(git status -s) ]]; then
        echo
        echo 'fyi, uncommitted changes or untracked files were found.'
        echo 'initial deployments must be from a "clean" branch.'
        echo 'cowardly refusal to proceed; please clean up and try again...'
        echo
        exit 1
        # read -p "continue as is? (y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
    fi

    if [[ $VERSION != "" ]]; then
        echo "installing and configuring version: $VERSION ..."
        git checkout -b deploy ${VERSION}
    else
        echo "no version specified; deploying code as is, but with necessary modifications."
    fi

    # echo "cleaning, resetting, and pulling..."
    # git clean -fd
    # git reset --hard
    # git pull -v
}

if [ $# -lt 2 -a "$1" != 'show' ]; then
    echo "Usage: $0 <enable|disable|deploy|updatejs|configure|show> <TENANT|CONFIGURATION|WEBAPP> (VERSION)"
    echo
    echo "where: TENANT = 'default' or the name of a deployable tenant"
    echo "       CONFIGURATION = <pycharm|dev|prod>"
    echo "       WEBAPP = one of the available webapps, e.g. 'search' or 'ireports'"
    echo "       VERSION = (optional) one of the available release candidates (tags)"
    echo
    echo "e.g. $0 disable ireports"
    echo "     $0 configure pycharm"
    echo "     $0 deploy botgarden 5.1.0-rc3"
    echo "     $0 show"
    echo
    exit 0
fi

if [[ ! -e manage.py ]]; then
    echo "no manage.py found. this script must be run in the django project directory"
    echo
    exit 1
fi

COMMAND=$1
# the second parameter can stand for several different things!
WEBAPP=$2
TENANT=$2
DEPLOYMENT=$2

# nb: version is optional. if not present, current repo, with or without changes is used...
VERSION="$3"

CURRDIR=`pwd`
CONFIGDIR=~/django_example_config

if [[ "${COMMAND}" = "disable" ]]; then
    perl -i -pe "s/('${WEBAPP}')/# \1/" cspace_django_site/installed_apps.py
    perl -i -pe "s/(url)/# \1/ if /${WEBAPP}/" cspace_django_site/urls.py
    echo "disabled ${WEBAPP}"
elif [[ "${COMMAND}" = "enable" ]]; then
    perl -i -pe "s/# *('${WEBAPP}')/\1/" cspace_django_site/installed_apps.py
    perl -i -pe "s/# *(url)/\1/ if /${WEBAPP}/" cspace_django_site/urls.py
    echo "enabled ${WEBAPP}"
elif [[ "${COMMAND}" = "show" ]]; then
    echo
    echo "Installed apps:"
    echo
    echo -e "from cspace_django_site.installed_apps import INSTALLED_APPS\nfor i in INSTALLED_APPS: print i" | $PYTHON
    echo
elif [[ "${COMMAND}" = "configure" ]]; then
    if [[ ! -f "cspace_django_site/extra_${DEPLOYMENT}.py" ]]; then
        echo "can't configure '${DEPLOYMENT}': use 'pycharm', 'dev', or 'prod'"
        echo
        exit
    fi

    # checkout correct version, if indicated...
    check_version

    cp cspace_django_site/extra_${DEPLOYMENT}.py cspace_django_site/extra_settings.py
    echo
    echo "*************************************************************************************************"
    echo "OK, \"${DEPLOYMENT}\" is configured. Now run ./setup.sh deploy <tenant> to set up a particular tenant,"
    echo "where <tenant> is either "default" (for non-specific tenant, i.e. nightly.collectionspace.org) or"
    echo "an existing tenant in the ${CONFIGDIR} repo"
    echo "*************************************************************************************************"
    echo
elif [[ "${COMMAND}" = "deploy" ]]; then
    if [[ ! -d "${CONFIGDIR}" ]]; then
        echo "the repo containing the configuration files (${CONFIGDIR}) does not exist"
        echo "please either create it (e.g. by cloning it from github)"
        echo "or edit this script to set the correct path"
        echo
        exit
    fi

    # checkout correct version, if indicated...
    check_version

    # for the generic "default" deployment, all the default apps and config are in this repo
    # no need to refer to the UCB custom repos
    if [[ "${COMMAND}" = "default" ]]; then
        cp config.examples/*.cfg config
        cp config.examples/*.csv config
        cp config.examples/*.json fixtures
        cp config.examples/project_urls.py cspace_django_site/urls.py
        cp config.examples/project_apps.py cspace_django_site/installed_apps.py
        cp client_modules/static_assets/cspace_django_site/images/CollectionToolzSmall.png client_modules/static_assets/cspace_django_site/images/header-logo.png
    else
        if [[ ! -d "${CONFIGDIR}/${TENANT}" ]]; then
            echo "can't deploy tenant ${TENANT}: ${CONFIGDIR}/${TENANT} does not exist"
            echo
            exit
        fi

        # for now, until versions in both django_example_config and cspace_django_project are sync'd
        # we don't check the version for the 'example' repo...
        # cd ${CONFIGDIR}
        # check_version
        # cd ${CURRDIR}

        rm config/*
        rm fixtures/*

        cp ${CONFIGDIR}/${TENANT}/config/* config
        cp ${CONFIGDIR}/${TENANT}/fixtures/* fixtures
        # note that in some cases, this cp will overwrite customized files in the underlying contributed apps
        # in cspace_django_project. that is the intended behavior!
        cp -r ${CONFIGDIR}/${TENANT}/apps/* .
        cp ${CONFIGDIR}/${TENANT}/project_urls.py cspace_django_site/urls.py
        cp ${CONFIGDIR}/${TENANT}/project_apps.py cspace_django_site/installed_apps.py
        cp client_modules/static_assets/cspace_django_site/images/header-logo-${TENANT}.png client_modules/static_assets/cspace_django_site/images/header-logo.png
    fi
    mv config/main.cfg cspace_django_site
    echo "*************************************************************************************************"
    echo "configured system is:"
    grep 'hostname' cspace_django_site/main.cfg
    echo "*************************************************************************************************"
    # just to be sure, we start over with the database...
    rm -f db.sqlite3
    # $PYTHON manage.py migrate
    $PYTHON manage.py syncdb --noinput
    $PYTHON manage.py loaddata fixtures/*.json
    # build js library, populate static dirs, rsync code to runtime dir, etc.
    deploy ${TENANT}
    echo
    echo "*************************************************************************************************"
    echo "Don't forget to check cspace_django_site/main.cfg if necessary and the rest of the"
    echo "configuration files in config/ (these are .cfg and .csv files)"
    echo
    echo "please restart apache to pick up changes"
    echo "*************************************************************************************************"
    echo
elif [[ "${COMMAND}" = "updatejs" ]]; then
    deploy ${TENANT}
    echo
    echo "*************************************************************************************************"
    echo "base javascript code updated; no changes to configuration or deployment though"
    echo
    echo "please restart apache to pick up changes!"
    echo "*************************************************************************************************"
    echo
else
    echo "${COMMAND} is not a recognized command."
fi
