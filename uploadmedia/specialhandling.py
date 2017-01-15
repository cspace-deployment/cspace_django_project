from re import compile, sub

def specialhandling(imageinfo, constants, BMUoptions, institution):
    if institution == 'botgarden':
        if 'extra' in imageinfo:
            try:
                for override in BMUoptions['overrides']:
                    if override[2] == 'creator':
                        for initials,refname in override[4]:
                            if imageinfo['extra'] == initials:
                                creator = refname
                                break
                imageinfo['creator'] = creator
            except:
                pass
