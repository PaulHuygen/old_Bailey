#!/usr/bin/env python
# checkdates.py -- Make list of session-dates.
# 20171101 Paul Huygen

corpusdir = "/Users/paul/projecten/cltl/oldbailey/OldBaileyCorpus2/OBC2"

import os
from KafNafParserPy import KafNafParser
from bs4 import BeautifulSoup
from dateutil.parser import parse

def get_docdate_of(soep):
    docdate = None
    for interp in soep.find_all('interp'):
        if interp['type'] == "date":
            datestr = interp['value']
            docdate = parse(datestr).isoformat()
            break
    return docdate 

for filename in os.listdir(corpusdir):
    filepath = os.path.join(corpusdir, filename)
    with open(filepath) as file:
        soup = BeautifulSoup(file, 'lxml')
        souptext = soup.find('text')
        docdate = get_docdate_of(souptext)
        print('{}: {}'.format(docdate, filename))
              
