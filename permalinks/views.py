__author__ = 'jblowe'

from django.shortcuts import redirect
from os import path

from common.appconfig import loadConfiguration, loadFields, getParms
from common import cspace # we use the config file reading function
from cspace_django_site import settings

searchConfig = cspace.getConfig(path.join(settings.BASE_PARENT_DIR, 'config'), 'search')
FIELDDEFINITIONS = searchConfig.get('search', 'FIELDDEFINITIONS')

# add in the the field definitions...
prmz = loadConfiguration('common')
prmz = loadFields(FIELDDEFINITIONS, prmz)

def get_item(request, itemid):

    x = prmz
    searchfield = ''
    for i in prmz.FIELDS['Search']:
        if 'objectno' in i['fieldtype']:
            searchfield = i['name']
            break
    return redirect('/search/search/?resultsOnly=true&displayType=full&maxresults=50&start=1&%s=%s' % (searchfield,itemid))
