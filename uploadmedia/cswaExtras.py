#!/usr/bin/env /usr/bin/python
# -*- coding: UTF-8 -*-

import os
import sys

import time
import urllib2
import re
import psycopg2
import base64

reload(sys)
sys.setdefaultencoding('utf-8')

timeoutcommand = "set statement_timeout to 240000; SET NAMES 'utf8';"


def getCSID(argType, arg, config):
    dbconn = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    if argType == 'objectnumber':
        query = """SELECT h.name from collectionobjects_common cc
JOIN hierarchy h on h.id=cc.id
JOIN misc on (cc.id = misc.id and misc.lifecyclestate <> 'deleted')
WHERE objectnumber = '%s'""" % arg
    elif argType == 'placeName':
        query = """SELECT h.name from places_common pc
JOIN hierarchy h on h.id=pc.id
JOIN misc on (pc.id = misc.id and misc.lifecyclestate <> 'deleted')
WHERE pc.refname ILIKE '%""" + arg + "%%'"

    objects.execute(query)
    return objects.fetchone()


MAXLOCATIONS = 1000

try:
    import xml.etree.ElementTree as etree
    #print("running with ElementTree")
except ImportError:
    try:
        from lxml import etree
        #print("running with lxml.etree")
    except ImportError:
        try:
            # normal cElementTree install
            import cElementTree as etree
            #print("running with cElementTree")
        except ImportError:
            try:
                # normal ElementTree install
                import elementtree.ElementTree as etree
                #print("running with ElementTree")
            except ImportError:
                print("Failed to import ElementTree from any known place")


def postxml(requestType, uri, realm, server, username, password, payload):

    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)

    unencoded_credentials = "%s:%s" % (username, password)
    auth_value = 'Basic %s' % base64.b64encode(unencoded_credentials).strip()
    opener.addheaders = [('Authorization', auth_value)]
    urllib2.install_opener(opener)
    url = "%s/cspace-services/%s" % (server, uri)
    request = urllib2.Request(url, payload, {'Content-Type': 'application/xml'})

    # default method for urllib2 with payload is POST
    if requestType == 'PUT': request.get_method = lambda: 'PUT'
    elapsedtime = 0.00
    try:
        elapsedtime = time.time()
        f = urllib2.urlopen(request)
        elapsedtime = time.time() - elapsedtime
    except urllib2.URLError, e:
        if hasattr(e, 'reason'):
            sys.stderr.write('We failed to reach a server.\n')
            sys.stderr.write('Reason: ' + str(e.reason) + '\n')
        if hasattr(e, 'code'):
            sys.stderr.write('The server couldn\'t fulfill the request.\n')
            sys.stderr.write('Error code: ' + str(e.code) + '\n')
        if True:
            #print 'Error in POSTing!'
            sys.stderr.write("Error in POSTing!\n")
            sys.stderr.write("%s\n" % url)
            sys.stderr.write(payload)
            raise

    data = f.read()
    info = f.info()
    # if a POST, the Location element contains the new CSID
    if info.getheader('Location'):
        csid = re.search(uri + '/(.*)', info.getheader('Location'))
        csid = csid.group(1)
    else:
        csid = ''
    return (url, data, csid, elapsedtime)


def relationsPayload(f):
    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="relations">
  <ns2:relations_common xmlns:ns2="http://collectionspace.org/services/relation" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <relationshipType>affects</relationshipType>
    <objectCsid>%s</objectCsid>
    <objectDocumentType>%s</objectDocumentType>
    <subjectCsid>%s</subjectCsid>
    <subjectDocumentType>%s</subjectDocumentType>
  </ns2:relations_common>
</document>
"""
    payload = payload % (f['objectCsid'], f['objectDocumentType'], f['subjectCsid'], f['subjectDocumentType'])
    return payload
