#!/usr/bin/env python
# Find all tags
import sys
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


import os
from KafNafParserPy import KafNafParser
from bs4 import BeautifulSoup
from dateutil.parser import parse
import re

# import dateutil

corpusdir = "/Users/paul/projecten/cltl/oldbailey/OldBaileyCorpus2/OBC2"
nafdir    = "/Users/paul/projecten/cltl/oldbailey/naf"


""" The last part of the name of an 'old bailey' xml-file contains the session date.
Extract the session date.
e.g. extract '17310428' from 'OBC2-17310428.xml'
"""
def extract_datestr_from_filename(filename):
    pat = re.compile('OBC2-(\d*).xml')
    m = pat.match(filename)
    return(m.group(1))


def naffilename_of(filename):
    filename_proper, extension = os.path.splitext(filename)
    return filename_proper + '.naf'


def _format_argument(label, value):
    "Format a an argument in an XML tag."
    if value == None:
        return ""
    else:
        return label + '="' + value + '"'



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
        if interp['type'] == "date":
            datestr = interp['value']
            docdate = parse(datestr).isoformat()
            break
    return docdate 
    
def get_docuri_of(soep):
    uri = None
    for interp in soep.find_all('interp'):
        if interp['type'] == "uri":
            uri = interp['value']
            break
    return uri


def extract_text_from_div1(divi):
    extracted_text = ""
    for ruwpar in divi.find_all('p'):
#        print(ruwpar.string)
        if ruwpar.string:
#            extracted_text = ruwpar.string
            extracted_text = extracted_text + '\n' + ruwpar.string
    return extracted_text

def generate_frontmatter_file(infilename, sessiondate, uri,  xmlsection):
    naffilename = sessiondate + '_f.naf'
    path_to_naffile = os.path.join(nafdir, naffilename)
    iso_sessiondate = parse(sessiondate).isoformat()
    for divi in xmlsection.find_all('div1'):
        if divi['type'] == 'frontMatter':
            print('Write {}'.format(path_to_naffile))
            with open(path_to_naffile, 'w') as naff:
                naff.write(naffile(extract_text_from_div1(divi), 'en', iso_sessiondate, uri, 'old_Bailey', infilename))
            break
        
def generate_casus_files(infilename, sessiondate, uri,  xmlsection):
    iso_sessiondate = parse(sessiondate).isoformat()
    for divi in xmlsection.find_all('div1'):
        if divi['type'] == 'trialAccount':
            accountnum = divi['n']
            naffilename = sessiondate + '_' + str(accountnum) + '.naf'
            path_to_naffile = os.path.join(nafdir, naffilename)
            with open(path_to_naffile, 'w') as naff:
#                naff.write(naffile(divi.findAll('p'), 'en', iso_sessiondate, uri, 'old_Bailey', infilename))
                naff.write(naffile(extract_text_from_div1(divi), 'en', iso_sessiondate, uri, 'old_Bailey', infilename))

def print_tags_in(elem):
    for sube in elem.contents:
        if sube.name:
            print(sube.name)
            print_tags_in(sube)
            

                
correctpat = re.compile('OBC2-(\d*).xml')
for filename in os.listdir(corpusdir):
    m = correctpat.match(filename)
    if not m:
        continue
    sessiondate = m.group(1)
    filepath = os.path.join(corpusdir, filename)
    print(filepath)
    with open(filepath) as file:
        soup = BeautifulSoup(file, 'lxml')
        souptext = soup.find('text')
        for para in souptext.find_all('p'):
            print_tags_in(para)
            
        
#        docdate = get_docdate_of(souptext)
#        doc_uri = get_docuri_of(souptext)
#        generate_frontmatter_file(filename, sessiondate, doc_uri, souptext)
#        generate_casus_files(filename, sessiondate, doc_uri, souptext)
#    break

        
#        for divi in souptext.find_all('div1'):
#            print("{}: {}: {}".format(filename, divi['id'], divi['type']))


#        print("Session date: {}".format(docdate))
#        print("Session uri: {}".format(doc_uri))


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
