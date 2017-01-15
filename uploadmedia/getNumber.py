from re import compile, sub

def getNumber(filename,institution):
    objectnumberpattern = compile('([a-z]+)\.([a-zA-Z0-9]+)')
    imagenumber = ''
    extra = ''
    # the following is only for bampfa filenames...
    # input is something like: bampfa_1995-46-194-a-199.jpg, output should be: 1995.46.194.a-199
    if institution == 'bampfa':
        objectnumber = filename.replace('bampfa_', '')
        try:
            objectnumber, imagenumber, imagetype = objectnumber.split('_')
        except:
            imagenumber = '1'
        # these legacy statement retained, just in case...
        # numHyphens = objectnumber.count("-") - 1
        #objectnumber = objectnumber.replace('-', '.', numHyphens)
        objectnumber = objectnumber.replace('-', '.')
        objectnumber = objectnumberpattern.sub(r'\1-\2', objectnumber)
    elif institution == 'ucjeps':
        # typically, UC1107670.JPG, but could be UC1107670_a_nice_pic.JPG
        filenameparts = filename.split('.')
        objectnumber = filenameparts[0]
        objectnumber = objectnumber.split('_')[0]
    elif institution == 'cinefiles':
        # e.g. 56306.p3.300gray.tif
        filenameparts = filename.split('.')
        objectnumber = filenameparts[0]
        imagenumber = filenameparts[1].replace('p','')
    # for pahma it suffices to split on underscore...
    elif institution == 'pahma':
        objectnumber = filename
        objectnumber = objectnumber.split('_')[0]
    elif institution == 'botgarden':
        # 12.1234_1_20170110_CL.jpg
        # i.e. accession number_image order_date(YYYYMMDD)_Initials of creator
        objectnumber = sub(r'(?i).(jpe?g|tiff?|png)$','',filename)
        try:
            objectnumber, imagenumber, yyymmdd, extra = objectnumber.split('_')
        except:
            imagenumber = '1'
            objectnumber = objectnumber.split('_')[0]
    else:
        objectnumber = filename
        objectnumber = objectnumber.split('_')[0]
    # the following is a last ditch attempt to get an object number from a filename...
    objectnumber = sub(r'(?i).(jpe?g|tiff?|png)$','',objectnumber)
    return filename, objectnumber, imagenumber, extra
