#!/usr/bin/env bash
# mostly untested!
set -e
if [ $# -lt 4 ];
then
  echo 1>&2 ""
  echo 1>&2 ""
  echo 1>&2 "call with four arguments:"
  echo 1>&2 ""
  echo 1>&2 "$0 fullpathtosolr4dir solrversion topnodename"
  echo 1>&2 ""
  echo 1>&2 "e.g. to install in the current directory"
  echo 1>&2 "$0  ~/solr4 4.10.4 topnode tenants"
  echo 1>&2 ""
  echo 1>&2 ""
  echo 1>&2 "- directory to create with all Solr goodies in it"
  echo 1>&2 "- solr4 version (e.g. 4.10.4)"
  echo 1>&2 "- topnodename is the directory with fullpathtosolr4dir in which"
  echo 1>&2 "  the data and configuration for all solr tenants goes"
  echo 1>&2 "- list of 1 or more tenants as a quoted string, e.g. (\"pahma botgarden ucjeps\""
  echo 1>&2 "  this will create 3 cores for each tenant, x-public, x-internal, x-media"
  echo 1>&2 ""
  echo 1>&2 "(solr4dir must not exist, but must be createable and writeable)"
  echo 1>&2 ""
  exit 2
fi
TOOLS=`pwd`
SOLR4=$1
SOLRVERSION=$2
SOLRTOPNODE=$3
TENANTS=$4
if [ -d $SOLR4 ];
then
   echo "$SOLR4 directory exists, please remove (e.g. rm -rf $SOLR4/), then try again."
   exit 1
fi
if [ ! -e /tmp/solr-$SOLRVERSION.tgz ];
then
   echo "solr-$SOLRVERSION.tgz does not exist, attempting to download"
   # install solr
   curl -o /tmp/solr-$SOLRVERSION.tgz http://mirror.symnds.com/software/Apache/lucene/solr/$SOLRVERSION/solr-$SOLRVERSION.tgz
fi
tar xzf /tmp/solr-$SOLRVERSION.tgz
mv solr-$SOLRVERSION $SOLR4
cd $SOLR4
mv example ${SOLRTOPNODE}

cd ${SOLRTOPNODE}/multicore/

rm -rf core0/
rm -rf core1/
rm -rf examplecdocs/

cp ${TOOLS}/solr.xml .

for tenant in ${TENANTS}
    do
    mkdir ${tenant}
    
    for core in public internal
    do
      cp -r ../example-schemaless/solr/collection1 ${tenant}/${core}
      perl -i -pe 's/collection1/${tenant}-${core}/' ${tenant}/${core}/core.properties
      cp ${TOOLS}/template.core.solrconfig.xml ${tenant}/${core}/conf/solrconfig.xml
      sed -e '/<\!-- COPYFIELDSGOHERE -->/r./${TOOLS}/schemaFragment.${core}.xml' ${TOOLS}/template.core.schema.xml > ${tenant}/${core}/conf/schema.xml
      # cp ${TOOLS}/template.core.schema.xml ${tenant}/${core}/conf/schema.xml
    done    

    # the media cores are special: they use the solr "managed-schema"
    cp -r ../example-schemaless/solr/collection1 ${tenant}/media
    perl -i -pe 's/collection1/${tenant}-media/' ${tenant}/media/core.properties

    echo "<!-- cores for ${tenant} -->" >> solr.xml
    for core in public internal media
    do
      perl -i -pe 's/TENANT\-CORE/${tenant}-${core}/' ${tenant}/${core}/conf/schema.xml
      echo "    <core name=\"${tenant}-${core}\" instanceDir=\"${tenant}/${core}\" />" >> solr.xml
    done
done

echo "  </cores>" >> solr.xml
echo "</solr>" >> solr.xml

echo
echo "*** Multicore solr4 installed for ${SOLRTOPNODE} deployments! ****"
echo "You can now start solr4. A good way to do this for development purposes is to use"
echo "the script made for the purpose, in the ${TOOLS} directory:"
echo "cp ${TOOLS}/startSolr.sh ${SOLR4}/${SOLRTOPNODE}"
echo "cd ${SOLR4}/${SOLRTOPNODE}"
echo "./startSolr.sh"
echo
echo "Let me try it for you..."
echo
cp ${TOOLS}/startSolr.sh ${SOLR4}/${SOLRTOPNODE}
cd ${SOLR4}/${SOLRTOPNODE}
./startSolr.sh
