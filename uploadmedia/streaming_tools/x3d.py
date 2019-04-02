import requests
import datetime
import xml.etree.ElementTree as ET


def make_x3d_url(md5):
    return "https://cspace-prod-02.ist.berkeley.edu/pahma_nuxeo/data/%s/%s/%s" % (md5[0:2], md5[2:4], md5)


def make_render_file(x3d_info):
    f = open('%s.html' % x3d_info[0], 'w')
    html = """<html>
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <title>%s</title>
    <script type='text/javascript' src='https://www.x3dom.org/download/x3dom.js'> </script>
    <link rel='stylesheet' type='text/css' href='https://www.x3dom.org/download/x3dom.css'/>
</head>
<body>
<h3>%s</h3>

    <x3d width='660px' height='660px'>
    <scene>
        <inline url="%s"></inline>
    </scene>
    </x3d>
</body>
</html>""" % (x3d_info[1], x3d_info[1], x3d_info[6])
    print >> f, html
    f.close()


url = 'https://pahma.cspace.berkeley.edu/cspace-services/blobs?kw=x3d&pgNum=0&pgSz=200&wf_deleted=false'
r = requests.get(url, auth=('jblowe@berkeley.edu', 'Pumpkins99'))
blobs = ET.fromstring(r.text)
md5keys = []
for blob_csid in blobs.findall('.//csid'):
    url = 'https://pahma.cspace.berkeley.edu/cspace-services/blobs/%s' % blob_csid.text
    b = requests.get(url, auth=('jblowe@berkeley.edu', 'Pumpkins99'))
    blob_record = ET.fromstring(b.text)
    x3d_info = [blob_record.find('.//%s' % x).text for x in 'digest name uri digest length updatedAt'.split(' ')]
    x3d_info = x3d_info + [make_x3d_url(blob_record.find('.//digest').text)]
    make_render_file(x3d_info)
    md5keys.append(x3d_info)
    pass

print '<html>'
print '<h3>X3D images in PAHMA CSpace</h3>'
print '<emph>%s</emph><hr/>' % datetime.datetime.now()
print '<table cell-padding="3px">'
print '<tr><th>'
print '<th>'.join('X3D rendering,Blob Record,MD5 key,Size,Updated At,Raw X3D file'.split(','))
for x3d_file_info in md5keys:
    print '<tr><td><a href="%s.html">%s</a><td><a href="https://pahma.cspace.berkeley.edu/cspace-services%s">XML blob record</a><td>%s<td>%s<td>%s<td><a href="%s">raw x3d file</a>' % tuple(
        x3d_file_info)
print '</table>'
