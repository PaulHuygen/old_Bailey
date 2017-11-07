#!/usr/bin/env python
import re
from bs4 import BeautifulSoup
from KafNafParserPy import KafNafParser
from dateutil.parser import parse

import os

def extract_text_from_tag(tag):
    extracted_text = ""  
    for elem in tag.contents:
        if not elem.name:
            extracted_text = extracted_text +  " " + elem
        elif elem.name == 'persname':
            name = extract_text_from_tag(elem)
            if not_a_name(name):
                name = 'Anonymus'
            extracted_text = extracted_text + ' ' + name
        elif elem.name == 'u':  
            extracted_text = extracted_text + ' "' + extract_text_from_tag(elem) + '"'
        else:            
            extracted_text = extracted_text + ' ' + extract_text_from_tag(elem)
    return extracted_text
def not_a_name(s):
    pat = re.compile("[A-Za-z]")
    return not pat.search(s)

def grab_text_from_xml_division(dsoup):
    grabbed_text = ''
    for par in dsoup.find_all('p'):  
        grabbed_text = grabbed_text + '\n' + remove_excessive_linebreaksfrom(extract_text_from_tag(par))
    return grabbed_text
  
def remove_excessive_linebreaksfrom(s):
    s = s.replace('\n', ' ')
    s = s.replace('      ', ' ')
    s = s.replace('     ', ' ')
    s = s.replace('    ', ' ')
    s = s.replace('   ', ' ')
    s = s.replace('  ', ' ')
    return s
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
     contents_start   = '<raw><' + '![CDATA['
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



if __name__ == '__main__':
    corpusdir = os.environ['corpusdir']
    
    nafdir = os.environ['nafdir']
    
    for filename in os.listdir(corpusdir):
        pat = re.compile('OBC2-(\d*).xml')
        m = pat.match(filename)
        if not m:
            continue
        sessiondatestring = m.group(1)
        
        filepath = os.path.join(corpusdir, filename)
        with open(filepath) as file:
            soup = BeautifulSoup(file, 'lxml')
            souptext = soup.find('text')
            for divi in souptext.find_all('div1'):
                naffilename = divi['id'] + '.naf'
                nafpath = os.path.join(nafdir, naffilename)
                sessiondate = parse(sessiondatestring)
                uri = 'http://cltl.nl/old_bailey/sessionpaper/' + divi['id']
                source = 'http://fedora.clarin-d.uni-saarland.de/oldbailey/downloads/OldBaileyCorpus2.zip'
                rawtext = grab_text_from_xml_division(divi)
                pubid = divi['id']
                with open(nafpath, 'w') as naff:
                    naff.write(naffile(rawtext, 'en', sessiondate.isoformat(), uri, source, pubid))
                

        
    
    

