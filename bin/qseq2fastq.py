"""
seq2fastq.py
"""
import glob
import sys
import os
import re
from optparse import OptionParser
from cStringIO import StringIO

shift31={'@':'!','A':'"','B':'#','C':'$','D':'%','E':'&','F':'\'','G':'(','H':')','I':'*','J':'+','K':',','L':'-','M':'.','N':'/','O':'0','P':'1','Q':'2','R':'3','S':'4','T':'5','U':'6','V':'7','W':'8','X':'9','Y':':','Z':';','[':'<','\\':'=',']':'>','^':'?','_':'@','`':'A','a':'B','b':'C','c':'D','d':'E','e':'F','f':'G','g':'H','h':'I','i':'J','j':'K','k':'L','l':'M','m':'N','n':'O','o':'P','p':'Q','q':'R','r':'S','s':'T','t':'U','u':'V','v':'W','w':'X','x':'Y','y':'Z','z':'\[','\{':'\\','|':']','}':'^','~':'_'}

def asciiConvert(quality,strip,striplast):

    asciList=[0]*(len(quality) - strip - striplast)
    
    for position in range(len(quality)):
        if position < strip:
            continue
        if position > len(quality) - striplast - 1:
            continue
        """
        FASTQ 33 is standard Sanger quality encoding, which means that
        you have to take the ASCII value of each character \
        in the quality string obtained from Illumina Sequencers (ascii
        64) and subtract 31 from it to get ascii 33 fastq files.
        The character is'C' == 67 and the '%' == 37. These would
        translate to Q scores of 34 and 4 which is an expected
        range of Phred scores.
        
        The quickest way to distinguish Sanger Q-score encoding
        (ASCII-33) from Illumina (Solexa) Q-score encoding (ASCII-64) \
        is to look for numerals [0-9] in the quality string. The
        numerals have ASCII values from 48-57 so it would be non-sensical
        to subtract 64 from them. If there are numerals in your quality
        string then the Q-score encoding is Sanger.
        """
        # - convert ascii 64 to ascii 33
        asciList[position-strip]=shift31.get(quality[position], '#')
        #asciList[position] = str(unichr((ord(quality[position])-31)))
        
    return asciList

def writeFastq(fh_in, fh_out, filter_reads, strip, striplast, fh_chastity):
    """
    Creates a fastq file from the shadow filtered qseq files
    and prints the appropriate files along with information 
    of the number of reads that were included (or excluded)
    from the final fastq files
    
    Required:
        - filehandle to the input filtered qseq files
        - filehandle to the output fastq files
        
    Returns:
        - nothing
        
    """
    tmp_data = StringIO()
    tmp_chastity = StringIO()
    lc = 0
    total_lines = 0
    num_chsty_fail = 0
    print "Filtering Reads: %s" %filter_reads
    if fh_chastity:
        print "Writing chastity too\n"
        
    if filter_reads == True: 
    
        #for line in fh_in.readlines():
        for line in fh_in:    
            #chastity flag filtering
                    
                line = line.split("\t")
                
                if not line[10].rstrip() == "0":
                    lc += 1
                    # - only include filtered reads (1)
                    converted_ascii = "".join(asciiConvert(line[9],strip,striplast))
                    end_pos = len(line[8]) - striplast
                    tmp_data.write("@%s_%s:%s:%s:%s:%s/%s\n%s\n%s\n%s\n" % (line[0], line[1], line[2], line[3], \
                        line[4],line[5],line[7],line[8][strip:end_pos],"+", converted_ascii))                    
                        
                    # flush to disk
                    if lc == 500000:
                        fh_out.write(tmp_data.getvalue())
                        tmp_data = StringIO()
                        total_lines = total_lines + lc
                        lc = 0
                else:
                    num_chsty_fail = num_chsty_fail + 1
                    continue    
        # - write out the remainder at the end
        total_lines = total_lines + lc
        fh_out.write(tmp_data.getvalue())
            
    if filter_reads == False:
        
        #for line in fh_in.readlines():
        for line in fh_in:    
            # - include all reads (0 & 1)

            lc += 1
            line = line.split("\t")
            converted_ascii = "".join(asciiConvert(line[9],strip,striplast))
            end_pos = len(line[8]) - striplast
            tmp_data.write("@%s_%s:%s:%s:%s:%s/%s\n%s\n%s\n%s\n" % (line[0], line[1], line[2], line[3], \
                        line[4],line[5],line[7],line[8][strip:end_pos],"+", converted_ascii))
            if fh_chastity and line[10].rstrip() == "0":
                tmp_chastity.write("%s_%s:%s:%s:%s:%s\n" % (line[0], line[1], line[2], line[3],line[4],line[5]))
                
            # flush to disk
            if lc == 500000:
                fh_out.write(tmp_data.getvalue())
                if fh_chastity:
                    fh_chastity.write(tmp_chastity.getvalue())
                    tmp_chastity = StringIO()
                tmp_data = StringIO()
                total_lines = total_lines + lc
                lc = 0
            
        # - write out the remainder at the end
        total_lines = total_lines + lc
        fh_out.write(tmp_data.getvalue())
        if fh_chastity:
            fh_chastity.write(tmp_chastity.getvalue())                    
            
    fh_out.close()
    if fh_chastity:
        fh_chastity.close()
    print "reads included: %s" %total_lines
    print "reads excluded: %s\n" %num_chsty_fail

    
def createFastq(fullpath, cfilter, strip, striplast, filename, output, chastity):
    
    """
    Preparing the file directories for the subsequent function
    Note: The fastq files will be written to the same directory 
          where the qseq files are stored
    Required:
        - full path to the where the qseq files are stored
        - indication of whether the file should exclude (Filter set to True)
          or include (Filter set to False [ i.e. DON'T FILTER ]) chastity failed reads
    """
    files = "*qseq.txt"
    if filename:
        files = filename
        
    qseqpath = os.path.join(fullpath,files)
    
    chastity_filter_name = ""
    if cfilter == True:
        # - chastity passed reads only
        chastity_filter_name = "cp" 
    if cfilter == False:
        # - include all reads
        chastity_filter_name = "ca"
    
    for i in glob.glob(qseqpath):
        
        print "\nFiltering: %s" %i
        
        flowcell = os.path.basename(i).split("_")[0]
        lane = os.path.basename(i).split("_")[1]
        read = os.path.basename(i).split("_")[2]
        
        fout = os.path.join(fullpath,"%s_%s_%s.fastq" %(flowcell, lane, read))
        fh_chastity = 0;

        if len(os.path.basename(i).split("_")) > 5:
            barcode = os.path.basename(i).split("_")[5]
            barcode = re.sub("\..*","",barcode)
            fout = os.path.join(fullpath,"%s_%s_%s_%s.fastq" %(flowcell, lane, read, barcode))
        if output:
            fout = os.path.join(fullpath, output)
        if chastity:
            chastity_out = os.path.join(fullpath, chastity)
            fh_chastity = open(chastity_out, 'w')
        fh_in = open(i, 'r')
        fh_out = open(fout, 'w')
        
        writeFastq(fh_in, fh_out, cfilter, strip, striplast, fh_chastity)
        
        
def main():
    
    """
    Getting information from the command line
    Required:
        -d directory
        -f filter on or off (optional) - Default is set to False
           meaning that all reads will be included in the fastq file
        -s strip the first N base off (optional) - Default 0
        -l strip the the last N base off (optional) - Default 0 
    """
    parser = OptionParser()
    
    parser.add_option("-d",help="directory where the qseq files are stored", dest = "directory", metavar="directory")
    parser.add_option("-f", "--filter out failed chastity reads", help="filter out failed chastity read - default \
                            includes all reads", dest="cfilter", default = False, action="store_true")
    parser.add_option("-s", "--strip first N", type="int", help="strip off first N bases - default \
                            no strip", dest="strip", default = 0, action="store")
    parser.add_option("-l", "--strip last N", type="int", help="strip off last N bases - default \
                            no strip", dest="striplast", default = 0, action="store")
    parser.add_option("-n", "--filename", dest = "filename", metavar="filename")
    parser.add_option("-o", "--output", dest = "output", metavar="output_file")
    parser.add_option("-c", "--chastity", dest = "chastity", metavar="chastity_file") 
    (options, args)=parser.parse_args()
    
    directory = options.directory
    cfilter = options.cfilter
    strip = options.strip
    striplast = options.striplast
    filename = options.filename
    output = options.output
    chastity = options.chastity
    createFastq(directory, cfilter, strip, striplast, filename, output, chastity)
main()
