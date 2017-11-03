#!/usr/bin/env python

import sys
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

from bs4 import BeautifulSoup
    
filename = 'speel.bewerkt.xml'


def extract_from_elem(elem):
    for sube in elem.contents:
        if sube.name:
            print(sube.name)
            extract_from_elem(sube)
            


with open(filename, 'r') as f:
    xml_content = f.read()
soep = BeautifulSoup(xml_content, 'lxml')

for divi in soep.find_all('div1'):
    print("\n\n {}:".format(divi['id']))
    extract_from_elem(divi)


    
#for divi in soep.find_all('div1'):
#    for par in divi.find_all('p'):
#        for elem in par.contents:
#            if elem.name == 'activity':
#                print(elem.name)
#                print(elem.string)
#            elif elem.name == 'hi':
#                print(elem.name)
#                print(elem.string)
##                if type(elem) == 'bs4.element.NavigableString':
##                    print(type(elem))
##                    print(elem.string)





#for divi in soep.find_all('div1'):
#    if divi['id'] == 't19130107-2':
#        for par in divi.find_all('p'):
#            for elem in par.contents:
#                print(elem.name)
#                if not elem.name:
#                    print(elem.string)
##                if type(elem) == 'bs4.element.NavigableString':
##                    print(type(elem))
##                    print(elem.string)

            

          
