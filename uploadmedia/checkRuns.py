import sys, os


def checkJobs(jobs, joberrors):
    totals = {}

    print "number of jobs found: %s " % len(jobs.keys())

    columnheaders = 'step1 original processed inprogress discrepancy logerrors'.split(' ')
    print
    # print "\t".join(columnheaders)
    for c in columnheaders: totals[c] = 0

    for job in sorted(jobs.keys(), reverse=True):
        steps = jobs[job]

        try:
            steps['discrepancy'] = steps['original'] - steps['processed']
        except:
            try:
                steps['discrepancy'] = steps['original']
            except:
                print 'no original for %s' % job
        # if steps['discrepancy'] == 0: del steps['discrepancy']
        if job in joberrors:
            steps['logerrors'] = joberrors[job]
        else:
            steps['logerrors'] = 0

        print job + ":\t",

        if steps['discrepancy'] == 0:
            print '%s images ingested' % steps['original'],
        else:
            try:
                print '%s images uploaded, %s ingested, %s problems' % (
                steps['original'], steps['processed'], steps['discrepancy']),
            except:
                print 'run files incomplete', steps,
        if steps['logerrors'] != 0:
            print '%s error messages seen in trace.log' % (steps['logerrors']),
        print
        for step in columnheaders:
            # print step."\t"
            if step in steps:
                #    print '%s\t' % steps[step],
                totals[step] += steps[step]
            # else:
            #    print '\t',
        # print

    print "totals\t",
    for step in columnheaders:
        if totals[step] != 0:
            print '%s %s, ' % (step, totals[step]),
    print


def checkMissing(images, missing):
    for name in images:
        isMissing = True
        runs = images[name]
        for run in runs:
            steps = runs[run]
            for step in steps:
                if step in 'processed|step1|inprogress'.split('|'): isMissing = False

    if isMissing: print "name ::: \tmissingname\n"


def checkDuplicates(images, duplicates, missing):
    for name in duplicates:
        if duplicates[name] > 1: print '%s duplicated %s times' % (name, duplicates[name])
    print


def checkCsids(csids):
    for name in csids:
        print name + "\t",
        CSIDlist = csids[name]
        for type in 'objectnumber blob media object'.split(' '):
            print CSIDlist[type],
        print


def checkSteps(images):
    for name in images:
        print name + "\t",
        runs = images[name]
        for run in runs:
            print run + "\t",
            steps = runs[run]
            for step in steps:
                print step + "\t",
        print


def usage():
    print "usage: python checkRuns.py <directory> <jobs missing duplicates images csids> [yyyy-mm-dd-hh-mm-ss]"


########## Main ##############
DIR = sys.argv[1]
images = {}
jobs = {}
missing = {}
duplicates = {}
joberrors = {}
errors = {}
csids = {}
JOB = {}

if len(sys.argv) < 3:
    usage()
    sys.exit(1)

if (sys.argv[1]):  # if we have a single job, just do stats for it..
    JOB = sys.argv[1]

files = []

for filename in os.listdir(DIR):
    if not '.csv' in filename: continue
    FH = open(os.path.join(DIR, filename), "rb")
    # filename = filename.replace('.csv','')
    (run, step, extension) = filename.split('.')
    for i, line in enumerate(FH.readlines()):
        objectCSID = ''
        if i == 0: continue  # skip header rows
        if step == 'processed':
            try:
                (name, size, objectnumber, date, creator, contributor, rightsholder, imagenumber, handling, approvedforweb,
                mediaCSID, objectCSID, blobCSID) = line.split('\t')
            except:
                (name, size, objectnumber, date, creator, contributor, rightsholder, imagenumber, handling, approvedforweb,
                mediaCSID, objectCSID) = line.split('\t')
                blobCSID = 'not provided'
        elif step == 'original' or step == 'step1':
            try:
                (name, size, objectnumber, date, creator, contributor, rightsholder, imagenumber, handling,
                 approvedforweb, description) = line.split('|')
            except:
                try:
                    (name, size, objectnumber, date, creator, contributor, rightsholder, imagenumber, handling,
                     approvedforweb) = line.split('|')
                except:
                    print 'skipped', filename, line
                    continue
        if objectCSID == 'not found': continue
        if not run in jobs: jobs[run] = {}
        if not step in jobs[run]: jobs[run][step] = 0
        if not name in images: images[name] = {}
        if not run in images[name]: images[name][run] = {}
        if not step in images[name][run]: images[name][run][step] = 0
        jobs[run][step] += 1
        images[name][run][step] += 1
        if step == 'processed':
            if not name in duplicates: duplicates[name] = 0
            duplicates[name] += 1
        if 'original' in step or 'step1' in step: missing[name] = filename
        if not name in csids:
            csids[name] = {'media': [], 'object': [], 'blob': []}
        csids[name]['objectnumber'] = objectnumber
        if step == 'processed':
            if mediaCSID and not mediaCSID in csids[name]['media']: csids[name]['media'].append(mediaCSID)
            if objectCSID and not objectCSID in csids[name]['object']: csids[name]['object'].append(objectCSID)
            if blobCSID and not blobCSID in csids[name]['blob']: csids[name]['blob'].append(blobCSID)

for filename in os.listdir(DIR):
    if not '.trace.log' in filename: continue
    FH = open(os.path.join(DIR, filename), "rb")
    filename = filename.replace('.trace.log', '')
    joberrors[filename] = 0
    for i, line in enumerate(FH.readlines()):

        error = False
        # next if /\/tmp\/upload_cache\/name/ # special case
        if 'Missing file' in line: error = True
        if 'Post did not return a 201 status code' in line: error = True
        if 'No output file' in line: error = True
        if error:
            # print _."\n"
            name = line.split(' ')
            joberrors[filename] += 1
            # print "error filename :: name :: error\n"
            errors[name] += error

if (sys.argv[2] == 'jobs'):
    print "Directory: DIR\n\n"
    checkJobs(jobs, joberrors)

elif (sys.argv[2] == 'missing'):
    checkMissing(images, missing)

elif (sys.argv[2] == 'duplicates'):
    checkDuplicates(images, duplicates)

elif (sys.argv[2] == 'images'):
    checkSteps(images)

elif (sys.argv[2] == 'csids'):
    checkCsids(csids)

else:
    usage()
