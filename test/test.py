#!/usr/bin/env python

import os
from KafNafParserPy import KafNafParser
from bs4 import BeautifulSoup
from dateutil.parser import *

corpusdir = "/home/paul/projecten/oldbailey/OldBaileyCorpus2/OBC2"

def naffilename_of(filename):
    filename_proper, extension = os.path.splitext(filename)
    return filename_proper + '.naf'

def naffile(text, lang, date, uri, source, pubID):
     "Write text to a raw naf file."
     file_start       = '<NAF xml:lang="{}" version="v3">'.format(lang)
     nafheader_start  = '<nafHeader>'

     file_description = '<fileDesc {} {} type="plain text" />'.format( _format_argument("source", source)
                                                                            , _format_argument("creationtime", date)
                                                                            )
     Id_tag = '<public {} {}/>'.format(_format_argument("publicId", pubID),  _format_argument("uri", uri))
     nafheader_end    = '</nafHeader>'
     contents_start   = '<raw><![CDATA['
     contents_end     = ']]></raw>'
     rawtext_part     = contents_start + text + contents_end
     file_end         = '</NAF>'
     return '\n'.join( [file_start
                       , nafheader_start
                       , file_description
                       , Id_tag
                       , nafheader_end
                       , rawtext_part
                       , file_end
                       ]
                     )

def get_docdate_of(soep):
    docdate = None
    for interp in soep.find_all('interp'):
        if interp.type == "date":
            datestr = interp.value
            docdate = datestr.isoformat()
            break
    return docdate 
    
def get_docuri_of(soep):
    uri = None
    for interp in soep.find_all('interp'):
        if interp.type == "uri":
            uri = interp.value
            break
    return uri
 

# def read_frontmatter(xmlsection):
    



for filename in os.listdir(corpusdir):
    filepath = os.path.join(corpusdir, filename)
    naffilename = naffilename_of(filename)
    print(filepath)
    naffile=KafNafParser(type='NAF')
    with open(filepath) as file:
        soup = BeautifulSoup(file, 'lxml')
        souptext = soup.find('text')
        docdate = get_docdate_of(souptext)
        doc_uri = get_docuri_of(souptext)
        print("Session date: {}".format(docdate))
        print("Session uri: {}".format(doc_uri))


#        for divi in souptext.find_all('div1'):
#            if divi['type'] == 'frontMatter':
#                read_frontmatter(divi)
#            else:
#                read_casus(divi)
                
#       nafheader = naffile.get_header()
#       naffile_desc = CfileDesc()
#       naffile_desc.set _filename
    
    
#        souptext = soup.find_all('text'):
#        docdate = get_docdate_of(souptext)
#        doc_uri = get_docuri_of(souptext)
#        doc_source = 
#        doc_pubid = 
#        naf=naffile(text, 'en', args.date, args.uri, args.source, args.public_id)
