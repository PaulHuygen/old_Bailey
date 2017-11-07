m4_include(inst.m4)m4_dnl
\documentclass[twoside]{artikel3}
\pagestyle{headings}
\usepackage{pdfswitch}
\usepackage{figlatex}
\usepackage{makeidx}
\renewcommand{\indexname}{General index}
\makeindex
\newcommand{\thedoctitle}{m4_doctitle}
\newcommand{\theauthor}{m4_author}
\newcommand{\thesubject}{m4_subject}
\newcommand{\NAF}{\textsc{naf}}
\newcommand{\POS}{\textsc{pos}}
\newcommand{\XML}{\textsc{xml}}
\title{\thedoctitle}
\author{\theauthor}
\date{m4_docdate}
m4_include(texinclusions.m4)m4_dnl
\begin{document}
\maketitle
\begin{abstract}
  This nuweb project generates a script to extract texts from the XML documents that have been provided in \href{https://www.oldbaileyonline.org/}{Old Bailey Online}.
\end{abstract}
\tableofcontents

\section{Introduction}
\label{sec:Introduction}

In the project ``\href{m4_oldbaileyonline_url}{old Bailey Online}'' digital versions of
reports of the proceedings in the ``Old Bailey'' in London have been
made available in \XML{} form. In order to use these proceeding in an
educational context we generate a script to transfer the \XML{} into
\NAF{} format and to load the files with metadata in Amcat.

At the moment we will not directly download the texts from
\texttt{oldbailey.org}, but use tarball with the collection, obtained
from
\href{http://www1.uni-giessen.de/oldbaileycorpus/}{the University of Giessen (BRD}.

\subsection{The collection with XML files}
\label{sec:collection}

The corpus consists of a collection of \XML{} files, one for each day
that there was a court session. Each XML file is divided up in
sections, each section wrapped in a \verb|div1| tag. The first section
is the ``frontmatter'' that lists the judges and the members of the
jury of that day.  Next sections, of type \verb|trialaccount| contain
the report of a single case that has been processed on that
day. Finally there is a section of type \verb|punishmentsummary| that
list the punishments that have been given out. and a section of type
\verb|advertisements| that contains advertisements. The section-type
is encoded in the \verb|id| attribute of the section
(table~\ref{tab:section-types}).%
\begin{table}[hbtp]
  \centering
  \begin{tabular}{lcl}
    \textbf{Type} & \textbf{C} & \textbf{Example} \\
    \texttt{frontmatter } & \texttt{f} & \texttt{f17200427-1}
    \texttt{trialaccount} & \texttt{t} & \texttt{t17200427-10} \\
    \texttt{punishmentsummary} & \texttt{s} & \texttt{s17200427-1} \\
    \texttt{advertisements} & \texttt{a} & \texttt{a17200427-1} \\
  \end{tabular}
  \caption{Section types (\texttt{div1}) in \XML{} files. \textbf{type}
  : name of the section-type (see text); \textbf{C}: character that
  encodes the type; \textbf{Example}: example of a section ID
  (contents of \texttt{id} attribute of the \texttt{div1} tag) as it
  occurs in source file \texttt{OBC2-17200427.xml} that contains the
  data of the session heald on april 27, 1720.
  \label{tab:section-types}}
\end{table}


We cannot extract all the information that is stored in the \XML{}
tags becaude they do not fit in the \NAF{}.

The name of a file with the serssions of one day is a concatenation of
\verb|OBC2-| or \verb|OBCPOS2-|, the date encoded as \verb|yyyymmdd|
and the extension \verb|.xml|. In files of which the names begin with
\verb|OBCPOS2| the words are labeled with \POS{} (Part Of Speech)
tags. Currently we cannot use these, so we have to skip these files.

\section{The program}
\label{sec:program}


\subsection{General}
\label{sec:general}



We will build a Python script that does the following:

\begin{enumerate}
\item read the \XML{} files one by one;
\item Generate separate \NAF{} files from each \verb|div1| section in
  each \XML{} file.
\item Use the \verb|id| attribute of the \verb|div1| tag as filename
  for the \NAF{} file.
\item Use the name of the \XML{} file as pubId.
\item Extract the session-date from the filename and write it as
  \emph{creation-date} in the \NAF{}.
\end{enumerate}


@d do the work @{@%
@< get path to XML inputfiles @(corpusdir@) @>
@< get path for NAF outputfiles @(nafdir@) @>
for filename in os.listdir(corpusdir):
    @< filter proper files and obtain sessiondate @(filename@,sessiondatestring@) @>
    filepath = os.path.join(corpusdir, filename)
    @< read the XML file and produce NAFs @(filepath@) @>
@|filename sessiondatestring @}

Environment variable \verb|corpusdir| points to the directory with the
\XML{} files and environment variable \verb|corpusdir| points to the
directory for the \NAF{} files to be generated.

@d get path to XML inputfiles @{@%
@1 = os.environ['corpusdir']
@|corpusdir @}

@d get path for NAF outputfiles @{@%
@1 = os.environ['nafdir']
@|nafdir @}


Analyse the filename. Skip the file if it is of the type that contains \POS{} tags.
Otherwise, extract the session-date.

@d filter proper files and obtain sessiondate @{@%
pat = re.compile('OBC2-(\d*).xml')
m = pat.match(@1)
if not m:
    continue
@2 = m.group(1)
@| @}


@d import modules @{@%
import re
@|re @}


Let us generate the structure of the Python script that we are going
to make.


@o ../bailey_to_naf.py @{@%
#!/usr/bin/env python
@< import modules @>
import os
@% @< global variables in bailey\_to\_naf @>

@< methods in bailey\_to\_naf @>

if __name__ == '__main__':
    @< do the work @>
    

@| @}


\subsection{Read and write}
\label{sec:read-and-write}

\subsubsection{Parse the XML file}
\label{sec:analyse-XML}

Use the BeautifulSoup module to parse the XML file.

@d import modules @{@%
from bs4 import BeautifulSoup
@|bs4 BeautifulSoup @}



Find the \verb|div1| sections in the \XML{} file. Open for each section a \NAF{} file with the \textsc{ID} of the section as filename and the session-date as timestamp.

@d read the XML file and produce NAFs @{@%
with open(@1) as file:
    soup = BeautifulSoup(file, 'lxml')
    souptext = soup.find('text')
    for divi in souptext.find_all('div1'):
@%        @< print the texts from the divi section @(divi@) @>
        @< generate a NAF file @(divi@,sessiondatestring@) @>

@| @}




\subsubsection{Extract the text from a div section}
\label{sec:ectractdiv}

A \verb|div1| section consists usually of a concatenation of text
strings and \XML{} tags that may also contain text-strings and
tags. So, to collect all the text strings, find the elements in the
tag, print elements that are text strings and recursively collect the
text-strings in the tags.

The text to be obtained is enclosed in \verb|p| tags.
A brief investigation revealed that the \verb|div1| sections may
contain the following tags:

\begin{description}
\item[activity] Contains quotation e.g ``(says this witness)'' .
\item[hi] Highlight the contained text.
\item[interp] Does not contain text, only references in the
  attributes.
\item[join] Does not contain text.
\item[persname] Name of a person. Sometimes it does not contain text,
  only referecnces.
\item[placename]  Name of a place.
\item[rs] Section
\item[u] Quote. Should be replaced by quote marks.
\item[xptr] Reference without text
\end{description}

We will recursively extract the text from the tags, replace a persname
tag without text-string by \verb|Persname| and replace \verb|<u>| and
\verb|</u>| tags by quote characters.

@d methods in bailey\_to\_naf @{@%
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
@| @}

Find out whether the text extracted from a \verb|persname| element contains characters. Otherwise, the tag does probably not contain a name.

@d methods in bailey\_to\_naf @{@%
def not_a_name(s):
    pat = re.compile("[A-Za-z]")
    return not pat.search(s)

@| @}


@d methods in bailey\_to\_naf @{@%
def grab_text_from_xml_division(dsoup):
    grabbed_text = ''
    for par in dsoup.find_all('p'):  
        grabbed_text = grabbed_text + '\n' + remove_excessive_linebreaksfrom(extract_text_from_tag(par))
    return grabbed_text
  
@|grab_text_from_xml @}


@d print the texts from the divi section @{@%
print("")
for par in @1.find_all('p'):
    print(remove_excessive_linebreaksfrom(extract_text_from_tag(par)))
@| @}


The extracted text seems to contain lots of linebreaks and double spaces. Let us remove them (admittedly in an awkward way).

@d methods in bailey\_to\_naf @{@%
def remove_excessive_linebreaksfrom(s):
    s = s.replace('\n', ' ')
    s = s.replace('      ', ' ')
    s = s.replace('     ', ' ')
    s = s.replace('    ', ' ')
    s = s.replace('   ', ' ')
    s = s.replace('  ', ' ')
    return s
@| @}


\subsubsection{Generate NAF}
\label{sec:generate_naf}

@d import modules @{@%
from KafNafParserPy import KafNafParser
@|KafNafParserPy @}


To generate naf we steal code from Emiel Miltenburg's \verb|text2naf| script.


@d methods in bailey\_to\_naf @{@%
def _format_argument(label, value):
    "Format a an argument in an XML tag."
    if value == None:
        return ""
    else:
        return label + '="' + value + '"'

@| @}



@d methods in bailey\_to\_naf @{@%
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

@| naffile @}




@d import modules @{@%
from dateutil.parser import parse
@|dateutil @}


@d generate a NAF file @{@%
naffilename = @1['id'] + '.naf'
nafpath = os.path.join(nafdir, naffilename)
sessiondate = parse(sessiondatestring)
uri = 'http://cltl.nl/old_bailey/sessionpaper/' + @1['id']
source = 'http://fedora.clarin-d.uni-saarland.de/oldbailey/downloads/OldBaileyCorpus2.zip'
rawtext = grab_text_from_xml_division(@1)
pubid = @1['id']
with open(nafpath, 'w') as naff:
    naff.write(naffile(rawtext, 'en', sessiondate.isoformat(), uri, source, pubid))

@| @}

\appendix

\section{How to read and translate this document}
\label{sec:translatedoc}

This document is an example of \emph{literate
  programming}~\cite{Knuth:1983:LP}. It contains the code of all sorts
of scripts and programs, combined with explaining texts. In this
document the literate programming tool \texttt{nuweb} is used, that is
currently available from Sourceforge
(URL:\url{m4_nuwebURL}). The advantages of Nuweb are, that
it can be used for every programming language and scripting language, that
it can contain multiple program sources and that it is very simple.


\subsection{Read this document}
\label{sec:read}

The document contains \emph{code scraps} that are collected into
output files. An output file (e.g. \texttt{output.fil}) shows up in the text as follows:

\begin{alltt}
"output.fil" \textrm{4a \(\equiv\)}
      # output.fil
      \textrm{\(<\) a macro 4b \(>\)}
      \textrm{\(<\) another macro 4c \(>\)}
      \(\diamond\)

\end{alltt}

The above construction contains text for the file. It is labelled with
a code (in this case 4a)  The constructions between the \(<\) and
\(>\) brackets are macro's, placeholders for texts that can be found
in other places of the document. The test for a macro is found in
constructions that look like:

\begin{alltt}
\textrm{\(<\) a macro 4b \(>\) \(\equiv\)}
     This is a scrap of code inside the macro.
     It is concatenated with other scraps inside the
     macro. The concatenated scraps replace
     the invocation of the macro.

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}

Macro's can be defined on different places. They can contain other macro´s.

\begin{alltt}
\textrm{\(<\) a scrap 87e \(>\) \(\equiv\)}
     This is another scrap in the macro. It is
     concatenated to the text of scrap 4b.
     This scrap contains another macro:
     \textrm{\(<\) another macro 45b \(>\)}

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}


\subsection{Process the document}
\label{sec:processing}

The raw document is named
\verb|a_<!!>m4_progname<!!>.w|. Figure~\ref{fig:fileschema}
\begin{figure}[hbtp]
  \centering
  \includegraphics{fileschema.fig}
  \caption{Translation of the raw code of this document into
    printable/viewable documents and into program sources. The figure
    shows the pathways and the main files involved.}
  \label{fig:fileschema}
\end{figure}
 shows pathways to
translate it into printable/viewable documents and to extract the
program sources. Table~\ref{tab:transtools}
\begin{table}[hbtp]
  \centering
  \begin{tabular}{lll}
    \textbf{Tool} & \textbf{Source} & \textbf{Description} \\
    gawk  & \url{www.gnu.org/software/gawk/}& text-processing scripting language \\
    M4    & \url{www.gnu.org/software/m4/}& Gnu macro processor \\
    nuweb & \url{nuweb.sourceforge.net} & Literate programming tool \\
    tex   & \url{www.ctan.org} & Typesetting system \\
    tex4ht & \url{www.ctan.org} & Convert \TeX{} documents into \texttt{xml}/\texttt{html}
  \end{tabular}
  \caption{Tools to translate this document into readable code and to
    extract the program sources}
  \label{tab:transtools}
\end{table}
lists the tools that are
needed for a translation. Most of the tools (except Nuweb) are available on a
well-equipped Linux system.


@d parameters in Makefile @{@%
NUWEB=m4_nuwebbinary
@| @}


\subsection{Translate and run}
\label{sec:transrun}

This chapter assembles the Makefile for this project.

@o Makefile -t @{@%
@< default target @>

@< parameters in Makefile @> 

@< impliciete make regels @>
@< expliciete make regels @>
@< make targets @>
@| @}

The default target of make is \verb|all|.

@d  default target @{@%
all : @< all targets @>
.PHONY : all

@|PHONY all @}


One of the targets is certainly the \textsc{pdf} version of this
document.

@d all targets @{m4_progname.pdf@}

We use many suffixes that were not known by the C-programmers who
constructed the \texttt{make} utility. Add these suffixes to the list.

@d parameters in Makefile @{@%
.SUFFIXES: .pdf .w .tex .html .aux .log .php

@| SUFFIXES @}



\subsection{Pre-processing}
\label{sec:pre-processing}

To make usable things from the raw input \verb|a_<!!>m4_progname<!!>.w|, do the following:

\begin{enumerate}
\item Process \verb|\$| characters.
\item Run the m4 pre-processor.
\item Run nuweb.
\end{enumerate}

This results in a \LaTeX{} file, that can be converted into a \pdf{}
or a \HTML{} document, and in the program sources and scripts.

\subsubsection{Process `dollar' characters }
\label{sec:procdollars}

Many ``intelligent'' \TeX{} editors (e.g.\ the auctex utility of
Emacs) handle \verb|\$| characters as special, to switch into
mathematics mode. This is irritating in program texts, that often
contain \verb|\$| characters as well. Therefore, we make a stub, that
translates the two-character sequence \verb|\\$| into the single
\verb|\$| character.


@d expliciete make regels @{@%
m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
	gawk '{if(match($$0, "@@<!!>%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_<!!>m4_progname.w \
          | gawk '{gsub(/[\\][\\$\$]/, "$$");print}'  > m4_<!!>m4_progname<!!>.w
@% $

@| @}

@%@d expliciete make regels @{@%
@%m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
@%
@%@% $
@%@| @}

\subsubsection{Run the M4 pre-processor}
\label{sec:run_M4}

@d  expliciete make regels @{@%
m4_progname<!!>.w : m4_<!!>m4_progname<!!>.w
	m4 -P m4_<!!>m4_progname<!!>.w > m4_progname<!!>.w

@| @}


\subsection{Typeset this document}
\label{sec:typeset}

Enable the following:
\begin{enumerate}
\item Create a \pdf{} document.
\item Print the typeset document.
\item View the typeset document with a viewer.
\item Create a \HTML document.
\end{enumerate}

In the three items, a typeset \pdf{} document is required or it is the
requirement itself.




\subsubsection{Figures}
\label{sec:figures}

This document contains figures that have been made by
\texttt{xfig}. Post-process the figures to enable inclusion in this
document.

The list of figures to be included:

@d parameters in Makefile @{@%
FIGFILES=fileschema

@| FIGFILES @}

We use the package \texttt{figlatex} to include the pictures. This
package expects two files with extensions \verb|.pdftex| and
\verb|.pdftex_t| for \texttt{pdflatex} and two files with extensions \verb|.pstex| and
\verb|.pstex_t| for the \texttt{latex}/\texttt{dvips}
combination. Probably tex4ht uses the latter two formats too.

Make lists of the graphical files that have to be present for
latex/pdflatex:

@d parameters in Makefile @{@%
FIGFILENAMES=\$(foreach fil,\$(FIGFILES), \$(fil).fig)
PDFT_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex_t)
PDF_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex)
PST_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex_t)
PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex)

@|FIGFILENAMES PDFT_NAMES PDF_FIG_NAMES PST_NAMES PS_FIG_NAMES@}


Create
the graph files with program \verb|fig2dev|:

@d impliciete make regels @{@%
%.eps: %.fig
	fig2dev -L eps \$< > \$@@

%.pstex: %.fig
	fig2dev -L pstex \$< > \$@@

.PRECIOUS : %.pstex
%.pstex_t: %.fig %.pstex
	fig2dev -L pstex_t -p \$*.pstex \$< > \$@@

%.pdftex: %.fig
	fig2dev -L pdftex \$< > \$@@

.PRECIOUS : %.pdftex
%.pdftex_t: %.fig %.pstex
	fig2dev -L pdftex_t -p \$*.pdftex \$< > \$@@

@| fig2dev @}


\subsubsection{Bibliography}
\label{sec:bbliography}

To keep this document portable, create a portable bibliography
file. It works as follows: This document refers in the
\texttt|bibliography| statement to the local \verb|bib|-file
\verb|m4_progname.bib|. To create this file, copy the auxiliary file
to another file \verb|auxfil.aux|, but replace the argument of the
command \verb|\bibdata{m4_progname}| to the names of the bibliography
files that contain the actual references (they should exist on the
computer on which you try this). This procedure should only be
performed on the computer of the author. Therefore, it is dependent of
a binary file on his computer.


@d expliciete make regels @{@%
bibfile : m4_progname.aux m4_mkportbib
	m4_mkportbib m4_progname m4_bibliographies

.PHONY : bibfile
@| @}

\subsubsection{Create a printable/viewable document}
\label{sec:createpdf}

Make a \pdf{} document for printing and viewing.

@d make targets @{@%
pdf : m4_progname.pdf

print : m4_progname.pdf
	m4_printpdf(m4_progname)

view : m4_progname.pdf
	m4_viewpdf(m4_progname)

@| pdf view print @}

Create the \pdf{} document. This may involve multiple runs of nuweb,
the \LaTeX{} processor and the bib\TeX{} processor, and depends on the
state of the \verb|aux| file that the \LaTeX{} processor creates as a
by-product. Therefore, this is performed in a separate script,
\verb|w2pdf|.

\paragraph{The w2pdf script}
\label{sec:w2pdf}

The three processors nuweb, \LaTeX{} and bib\TeX{} are
intertwined. \LaTeX{} and bib\TeX{} create parameters or change the
value of parameters, and write them in an auxiliary file. The other
processors may need those values to produce the correct output. The
\LaTeX{} processor may even need the parameters in a second
run. Therefore, consider the creation of the (\pdf) document finished
when none of the processors causes the auxiliary file to change. This
is performed by a shell script \verb|w2pdf|.

@%@d make targets @{@%
@%m4_progname.pdf : m4_progname.w \$(FIGFILES)
@%	chmod 775 bin/w2pdf
@%	bin/w2pdf m4_progname
@%
@%@| @}



Note, that in the following \texttt{make} construct, the implicit rule
\verb|.w.pdf| is not used. It turned out, that make did not calculate
the dependencies correctly when I did use this rule.

@d  impliciete make regels@{@%
@%.w.pdf :
%.pdf : %.w \$(W2PDF)  \$(PDF_FIG_NAMES) \$(PDFT_NAMES)
	chmod 775 \$(W2PDF)
	\$(W2PDF) \$*

@| @}

The following is an ugly fix of an unsolved problem. Currently I
develop this thing, while it resides on a remote computer that is
connected via the \verb|sshfs| filesystem. On my home computer I
cannot run executables on this system, but on my work-computer I
can. Therefore, place the following script on a local directory.

@d parameters in Makefile @{@%
W2PDF=m4_nuwebbindir/w2pdf
@| @}

@d directories to create @{m4_nuwebbindir @| @}

@d expliciete make regels  @{@%
\$(W2PDF) : m4_progname.w
	\$(NUWEB) m4_progname.w
@| @}

m4_dnl
m4_dnl Open compile file.
m4_dnl args: 1) directory; 2) file; 3) Latex compiler
m4_dnl
m4_define(m4_opencompilfil,
<!@o !>\$1<!!>\$2<! @{@%
#!/bin/bash
# !>\$2<! -- compile a nuweb file
# usage: !>\$2<! [filename]
# !>m4_header<!
NUWEB=m4_nuwebbinary
LATEXCOMPILER=!>\$3<!
@< filenames in nuweb compile script @>
@< compile nuweb @>

@| @}
!>)m4_dnl

m4_opencompilfil(<!m4_nuwebbindir/!>,<!w2pdf!>,<!pdflatex!>)m4_dnl

@%@o w2pdf @{@%
@%#!/bin/bash
@%# w2pdf -- make a pdf file from a nuweb file
@%# usage: w2pdf [filename]
@%#  [filename]: Name of the nuweb source file.
@%`#' m4_header
@%echo "translate " \$1 >w2pdf.log
@%@< filenames in w2pdf @>
@%
@%@< perform the task of w2pdf @>
@%
@%@| @}

The script retains a copy of the latest version of the auxiliary file.
Then it runs the four processors nuweb, \LaTeX{}, MakeIndex and bib\TeX{}, until
they do not change the auxiliary file or the index. 

@d compile nuweb @{@%
NUWEB=m4_nuweb
@< run the processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}

The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in nuweb compile script @{@%
nufil=\$1
trunk=\${1%%.*}
texfil=\${trunk}.tex
auxfil=\${trunk}.aux
oldaux=old.\${trunk}.aux
indexfil=\${trunk}.idx
oldindexfil=old.\${trunk}.idx
@| nufil trunk texfil auxfil oldaux indexfil oldindexfil @}

Remove the old copy if it is no longer needed.
@d remove the copy of the aux file @{@%
rm \$oldaux
@| @}

Run the three processors. Do not use the option \verb|-o| (to suppres
generation of program sources) for nuweb,  because \verb|w2pdf| must
be kept up to date as well.

@d run the three processors @{@%
\$NUWEB \$nufil
\$LATEXCOMPILER \$texfil
makeindex \$trunk
bibtex \$trunk
@| nuweb makeindex bibtex @}


Repeat to copy the auxiliary file and the index file  and run the processors until the
auxiliary file and the index file are equal to their copies.
 However, since I have not yet been able to test the \verb|aux|
file and the \verb|idx| in the same test statement, currently only the
\verb|aux| file is tested.

It turns out, that sometimes a strange loop occurs in which the
\verb|aux| file will keep to change. Therefore, with a counter we
prevent the loop to occur more than m4_maxtexloops times.

@d run the processors until the aux file remains unchanged @{@%
LOOPCOUNTER=0
while
  ! cmp -s \$auxfil \$oldaux 
do
  if [ -e \$auxfil ]
  then
   cp \$auxfil \$oldaux
  fi
  if [ -e \$indexfil ]
  then
   cp \$indexfil \$oldindexfil
  fi
  @< run the three processors @>
  if [ \$LOOPCOUNTER -ge 10 ]
  then
    cp \$auxfil \$oldaux
  fi;
done
@| @}


\subsubsection{Create HTML files}
\label{sec:createhtml}

\textsc{Html} is easier to read on-line than a \pdf{} document that
was made for printing. We use \verb|tex4ht| to generate \HTML{}
code. An advantage of this system is, that we can include figures
in the same way as we do for \verb|pdflatex|.

Nuweb creates a \LaTeX{} file that is suitable
for \verb|latex2html| if the source file has \verb|.hw| as suffix instead of
\verb|.w|. However, this feature is not compatible with tex4ht.

Make html file:

@d make targets @{@%
html : m4_htmltarget

@| @}

The \HTML{} file depends on its source file and the graphics files.

Make lists of the graphics files and copy them.

@d parameters in Makefile @{@%
HTML_PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex)
HTML_PST_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex_t)
@| @}


@d impliciete make regels @{@%
m4_htmldocdir/%.pstex : %.pstex
	cp  \$< \$@@

m4_htmldocdir/%.pstex_t : %.pstex_t
	cp  \$< \$@@

@| @}

Copy the nuweb file into the html directory.

@d expliciete make regels @{@%
m4_htmlsource : m4_progname.w
	cp  m4_progname.w m4_htmlsource

@| @}

We also need a file with the same name as the documentstyle and suffix
\verb|.4ht|. Just copy the file \verb|report.4ht| from the tex4ht
distribution. Currently this seems to work.

@d expliciete make regels @{@%
m4_4htfildest : m4_4htfilsource
	cp m4_4htfilsource m4_4htfildest

@| @}

Copy the bibliography.

@d expliciete make regels  @{@%
m4_htmlbibfil : m4_anuwebdir/m4_progname.bib
	cp m4_anuwebdir/m4_progname.bib m4_htmlbibfil

@| @}



Make a dvi file with \texttt{w2html} and then run
\texttt{htlatex}. 

@d expliciete make regels @{@%
m4_htmltarget : m4_htmlsource m4_4htfildest \$(HTML_PS_FIG_NAMES) \$(HTML_PST_NAMES) m4_htmlbibfil
	cp w2html m4_abindir
	cd m4_abindir && chmod 775 w2html
	cd m4_htmldocdir && m4_abindir/w2html m4_progname.w

@| @}

Create a script that performs the translation.

@%m4_<!!>opencompilfil(m4_htmldocdir/,`w2dvi',`latex')m4_dnl


@o w2html @{@%
#!/bin/bash
# w2html -- make a html file from a nuweb file
# usage: w2html [filename]
#  [filename]: Name of the nuweb source file.
<!#!> m4_header
echo "translate " \$1 >w2html.log
NUWEB=m4_nuwebbinary
@< filenames in w2html @>

@< perform the task of w2html @>

@| @}

The script is very much like the \verb|w2pdf| script, but at this
moment I have still difficulties to compile the source smoothly into
\textsc{html} and that is why I make a separate file and do not
recycle parts from the other file. However, the file works similar.


@d perform the task of w2html @{@%
@< run the html processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}


The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in w2html @{@%
nufil=\$1
trunk=\${1%%.*}
texfil=\${trunk}.tex
auxfil=\${trunk}.aux
oldaux=old.\${trunk}.aux
indexfil=\${trunk}.idx
oldindexfil=old.\${trunk}.idx
@| nufil trunk texfil auxfil oldaux @}

@d run the html processors until the aux file remains unchanged @{@%
while
  ! cmp -s \$auxfil \$oldaux 
do
  if [ -e \$auxfil ]
  then
   cp \$auxfil \$oldaux
  fi
@%  if [ -e \$indexfil ]
@%  then
@%   cp \$indexfil \$oldindexfil
@%  fi
  @< run the html processors @>
done
@< run tex4ht @>

@| @}


To work for \textsc{html}, nuweb \emph{must} be run with the \verb|-n|
option, because there are no page numbers.

@d run the html processors @{@%
\$NUWEB -o -n \$nufil
latex \$texfil
makeindex \$trunk
bibtex \$trunk
htlatex \$trunk
@| @}


When the compilation has been satisfied, run makeindex in a special
way, run bibtex again (I don't know why this is necessary) and then run htlatex another time.
@d run tex4ht @{@%
m4_index4ht
makeindex -o \$trunk.ind \$trunk.4dx
bibtex \$trunk
htlatex \$trunk
@| @}


\paragraph{create the program sources}
\label{sec:createsources}

Run nuweb, but suppress the creation of the \LaTeX{} documentation.
Nuweb creates only sources that do not yet exist or that have been
modified. Therefore make does not have to check this. However,
``make'' has to create the directories for the sources if they
do not yet exist.
@%This is especially important for the directories
@%with the \HTML{} files. It seems to be easiest to do this with a shell
@%script.
So, let's create the directories first.

@d parameters in Makefile @{@%
MKDIR = mkdir -p

@| MKDIR @}



@d make targets @{@%
DIRS = @< directories to create @>

\$(DIRS) : 
	\$(MKDIR) \$@@

@| DIRS @}


@d make targets @{@%
sources : m4_progname.w \$(DIRS)
@%	cp ./createdirs m4_bindir/createdirs
@%	cd m4_bindir && chmod 775 createdirs
@%	m4_bindir/createdirs
	\$(NUWEB) m4_progname.w

@| @}

@%@o createdirs @{@%
@%#/bin/bash
@%# createdirs -- create directories
@%`#' m4_header
@%@< create directories @>
@%@| @}


\section{References}
\label{sec:references}

\subsection{Literature}
\label{sec:literature}

\bibliographystyle{plain}
\bibliography{m4_progname}

\subsection{URL's}
\label{sec:urls}

\begin{description}
\item[Nuweb:] \url{m4_nuwebURL}
\end{description}

\section{Indexes}
\label{sec:indexes}


\subsection{Filenames}
\label{sec:filenames}

@f

\subsection{Macro's}
\label{sec:macros}

@m

\subsection{Variables}
\label{sec:veriables}

@u

\end{document}

% Local IspellDict: british 

% LocalWords:  Webcom

