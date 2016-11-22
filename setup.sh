#
# script to help deploy webapps
#
# essentially a type of 'make' file.
#
# the project can be set up to run in Prod, Dev, and Pycharm environments with 'configure'
# the project can be customized for any of the UCB deployments with 'deploy'
# individual webapps can be enabled and disabled
#

if [ $# -ne 2 -a "$1" != 'show' ]; then
    echo "Usage: $0 <enable|disable|deploy|redeploy|configure|show> <TENANT|CONFIGURATION|WEBAPP>"
    echo
    echo "where: TENANT = 'default' or the name of a deployable tenant"
    echo "       CONFIGURATION = <pycharm|dev|prod>"
    echo "       WEBAPP = one of the available webapps, e.g. 'search' or 'ireports'"
    echo
    echo "e.g. $0 disable ireports"
    echo "     $0 configure pycharm"
    echo "     $0 deploy botgarden"
    echo "     $0 show"
    echo
    exit
fi

COMMAND=$1
WEBAPP=$2
CURRDIR=`pwd`
CONFIGDIR=~/django_example_config

if [ "${COMMAND}" = "disable" ]; then
    perl -i -pe "s/('$WEBAPP')/#* *\1/" cspace_django_site/installed_apps.py
    perl -i -pe "s/(url)/#* *\1/ if /$WEBAPP/" cspace_django_site/urls.py
    echo "disabled $WEBAPP"
elif [ "${COMMAND}" = "enable" ]; then
    perl -i -pe "s/#* *('$WEBAPP')/\1/" cspace_django_site/installed_apps.py
    perl -i -pe "s/#* *(url)/\1/ if /$WEBAPP/" cspace_django_site/urls.py
    echo "enabled $WEBAPP"
elif [ "${COMMAND}" = "show" ]; then
    echo
    echo "Installed apps:"
    echo
    echo -e "from cspace_django_site.installed_apps import INSTALLED_APPS\nfor i in INSTALLED_APPS: print i" | python
    echo
elif [ "${COMMAND}" = "configure" ]; then
    if [ ! -f "cspace_django_site/extra_$2.py" ]; then
        echo "can't configure '$2': use 'pycharm', 'dev', or 'prod'"
        echo
        exit
    fi
    cp cspace_django_site/extra_$2.py cspace_django_site/extra_settings.py
    # install and build the javascript framework
    npm install
    npm build
    ./node_modules/.bin/eslint client_modules/js/app.js
    echo
    echo "*************************************************************************************************"
    echo "OK, \"$2\" is configured. Now run ./setup.sh deploy <tenant> to set up a particular tenant,"
    echo "where <tenant> is either "default" (for non-specific tenant, i.e. nightly.collectionspace.org) or"
    echo "an existing tenant in the django_example_config repo"
    echo "*************************************************************************************************"
    echo
elif [ "${COMMAND}" = "deploy" ]; then
    if [ ! -d "${CONFIGDIR}" ]; then
        echo "the repo containing the configuration files (${CONFIGDIR}) does not exist"
        echo "please either create it (e.g. by cloning it from github)"
        echo "or edit this script to set the correct path"
        echo
        exit
    fi
    # clean out the config directory of these four types of files.
    rm -f config/*.cfg
    rm -f config/*.csv
    rm -f config/*.xml
    rm -f fixtures/*.json
    if [ "$2" = "default" ]; then
        cp config.examples/*.cfg config
        cp config.examples/*.csv config
        cp config.examples/*.json fixtures
        cp config.examples/project_urls.py cspace_django_site/urls.py
        cp config.examples/project_apps.py cspace_django_site/installed_apps.py
        cp client_modules/static_assets/cspace_django_site/images/CollectionToolzSmall.png client_modules/static_assets/cspace_django_site/images/header-logo.png
    else
        if [ ! -d "${CONFIGDIR}/$2" ]; then
            echo "can't deploy tenant $2: ${CONFIGDIR}/$2 does not exist"
            echo
            exit
        fi
        cd ${CONFIGDIR}
        git pull -v
        cd ${CURRDIR}
        cp ${CONFIGDIR}/$2/config/* config
        cp ${CONFIGDIR}/$2/fixtures/* fixtures
        cp -r ${CONFIGDIR}/$2/apps/* .
        rm -f README
        cp ${CONFIGDIR}/$2/project_urls.py cspace_django_site/urls.py
        cp ${CONFIGDIR}/$2/project_apps.py cspace_django_site/installed_apps.py
        cp client_modules/static_assets/cspace_django_site/images/header-logo-$2.png client_modules/static_assets/cspace_django_site/images/header-logo.png

    fi
    mv config/main.cfg cspace_django_site
    # just to be sure, we start over with the database...
    rm -f db.sqlite3
    python manage.py syncdb --noinput
    # python manage.py migrate
    python manage.py loaddata fixtures/*.json
    # do this just in case the javascript has been tweaked
    npm install
    ./node_modules/.bin/webpack
    python manage.py collectstatic --noinput
    echo
    echo "*************************************************************************************************"
    echo "Don't forget to check cspace_django_site/main.cfg if necessary and the rest of the"
    echo "configuration files in config/ (these are .cfg and .csv files)"
    echo
    echo "please restart apache to pick up changes"
    echo "*************************************************************************************************"
    echo
elif [ "${COMMAND}" = "redeploy" ]; then
    git checkout master
    git pull -v
    TAG=`git tag | sort -k2 -t"-" -rn | head -1`
    echo "*************************************************************************************************"
    echo ">>>> deploying $TAG"
    echo "*************************************************************************************************"
    git checkout ${TAG}
    # do this just in case the javascript has been tweaked
    ./node_modules/.bin/webpack
    python manage.py collectstatic --noinput
    echo
    echo "*************************************************************************************************"
    echo "please restart apache to pick up changes"
    echo "*************************************************************************************************"
    echo
elif [ "${COMMAND}" = "refresh" ]; then
    cd ${CONFIGDIR}
    git pull -v
    cd ${CURRDIR}
    cp -r ${CONFIGDIR}/$2/apps/* .
    # get rid of any README that might have come over with the cp of the apps.
    rm -f README
    # the underlying cspace_django_project code should be up to date as well...
    git pull -v
    # do this just in case the javascript has been tweaked
    ./node_modules/.bin/webpack
    python manage.py collectstatic --noinput
    echo
    echo "*************************************************************************************************"
    echo "code (only) refreshed from GitHub; no changes to configuration or fixtures though"
    echo
    echo "please restart apache to pick up changes!"
    echo "*************************************************************************************************"
    echo
else
    echo "${COMMAND} is not a recognized command."
fi
