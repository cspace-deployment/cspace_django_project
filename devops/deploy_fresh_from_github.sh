set -e
if [ $# -ne 3 ];
then
  echo "completely cleans out deployment-directory and reploys specified django webapps from scratch"
  echo
  echo "$0 deployment-directory [tenant|default] [pycharm|dev|prod]"
  echo
  echo "e.g. $0 ~/pahma-dev pahma dev"
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
rm -rf *
rm -rf .git
rm -f .gitignore
rm -f .eslintrc.js
rm -f .babelrc
git clone https://github.com/cspace-deployment/cspace_django_project.git .
./setup.sh configure $3
./setup.sh deploy $2
