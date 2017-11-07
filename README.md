# old_Bailey
Process files from the
[Old Bailey on-line](https://www.oldbaileyonline.org) project.
Convert the files (obtained from
[the University of Giessen](http://www1.uni-giessen.de/oldbaileycorpus/)
into "raw"
[NAF format](https://github.com/cltl/KafNafParserPy/blob/master/naf.dtd).

## Manual

1. Download
   [OldBaileyCorpus2.zip](http://fedora.clarin-d.uni-saarland.de/oldbailey/downloads/OldBaileyCorpus2.zip)
   and unpack it somewhere. It contains a sub-directory `OBC2` with
   \XML{} encoded reports of the sessions held in the Old Bailey.
2. Set the following environment parameters:
    **corpusdir** : Path to the `OBC2` directory
    **nafdir** : Path to the directory whre the NAF files ought to go.
3. Make sure that `nafdir` exists.
4. run `python bailey_to_naf.py`


