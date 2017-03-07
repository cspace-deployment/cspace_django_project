set -e
if [ $# -lt 2 ];
then
  echo "updates django base code and tenant apps; attempts to set all config files to dev configuration"
  echo "you'll need to check postgres config and passwords"
  echo
  echo "$0 deployment-directory [tenant|default]"
  echo
  echo "e.g. $0 ~/pahma-dev pahma"
  echo
  exit 1
fi
if [ ! -e $1 ];
then
  echo "directory $1 does not exist."
  exit 1
fi
echo "making a backup in $1.backup..."
rsync -r --links $1/ $1.backup
cd $1
git pull -v
./setup.sh deploy $2
perl -i -pe 's/.cspace.berkeley/-dev.cspace.berkeley/ unless /(\-dev|urn\:|\@)/' cspace_django_site/main.cfg
perl -i -pe 's/.cspace.berkeley/-dev.cspace.berkeley/ unless /(\-dev|urn\:|\@)/' config/*.cfg
perl -i -pe 's/prod\-/dev-/ unless /\-dev/;s/port=53/port=51/;' config/*.cfg
perl -i -pe 's/production/development/' config/*.cfg
perl -i -pe 's/green/red/' config/*.cfg
grep hostname cspace_django_site/main.cfg
