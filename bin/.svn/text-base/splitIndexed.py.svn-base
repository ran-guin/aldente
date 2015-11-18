import os, csv

def splitSeqByIndices(taglibF=None, reportF=None, indices=None, indexPos=0, indexCol=8, countCol=None, chars='ACGT.', oneOff=True, colDelimiter='\t', stripIndex=True, outDir=None, stripExtra=0):
	"""
	split a file by indices
	indices is index sequences in a set
	indexPos is the position of the index in a read. 6 means the first 6 bases is an index; -6 means the last 6 bases is an index; 0 means index is NOT a part of a read.
	"""
	indexCol=int(indexCol)
	stripExtra=int(stripExtra)
	if indexPos:
		indexPos = int(indexPos)
	if countCol:
		countCol = int(countCol)

	def oneSubs(s):
		"""return a set of sequences with single base substitution of the original"""
		c = set([''.join([s[:i], j, s[i+1:]]) for i in xrange(len(s)) for j in chars])
		c.remove(s)
		return c
	# By default, indexCol holds only the index, and writes out original records
	def idx(r):
		return r[indexCol].strip()
	
	def toWrite(r):
		pass
	
	if stripIndex:
		def toWrite(r):
			r.pop(indexCol)
	# part of the sequence in indexCol is index
	if indexPos:
		if indexPos > 0:
			def idx(r):
				return r[indexCol].strip()[:indexPos]
			if stripIndex:
				def toWrite(r):
					r[indexCol] = r[indexCol].strip()[indexPos:]
					r[indexCol+1] = r[indexCol+1].strip()[indexPos:]
				if stripExtra:
					def toWrite(r):
					 r[indexCol] = r[indexCol].strip()[indexPos+stripExtra:]
					 r[indexCol+1] = r[indexCol+1].strip()[indexPos+stripExtra:]
		else:
			def idx(r):
				return r[indexCol].strip()[indexPos:]
			if stripIndex:
				def toWrite(r):
					r[indexCol] = r[indexCol].strip()[:indexPos]
	prefixes = list(indices)
	prefixes.append('noMatch')
	prefixes.append('ambiguous')
	ambiguousPrefix = []
	print "prefixes ", prefixes
	parentCountFileRecordLen = {}
	#summary = {'noMatch': ['NA', 0], 'ambiguous': ['NA', 0]}
	base, ext = os.path.splitext(os.path.basename(taglibF))
	for p in prefixes:
		aFile = ''.join([outDir, '/', base, '_', p, ext])
		fout = open(aFile, 'w');
		fout.close()
		# store parent, count, subTaglibF, a tmp list of records, len of the list
		parentCountFileRecordLen[p] = [p, 0, aFile, [], 0, 0]
	if oneOff:
		for p in prefixes[:-2]:
			oneOffIndices = oneSubs(p)
			for a in oneOffIndices:
				if a in parentCountFileRecordLen:
					#raise RuntimeError, "%s, one-off of %s is already associated with a file handle %s" % (a, p, subTaglibFHDict[a][0])
					parentCountFileRecordLen[a] = ['ambiguous', 0, parentCountFileRecordLen['ambiguous'][2], [], 0, 0]
					ambiguousPrefix.append((a, p))
				else:
					parentCountFileRecordLen[a] = [p, 0, parentCountFileRecordLen[p][2], [], 0, 0]
	totalTags = 0
	c = 0
	fin = open(taglibF, 'r')
	try:
		for r in csv.reader(fin, delimiter=colDelimiter):
			try:
				c = int(r[countCol])
			except:
				c = 1
			totalTags += c
			a = idx(r)
			toWrite(r)
			if a in parentCountFileRecordLen:
				g = a
			else:
				g = 'noMatch'
			parentCountFileRecordLen[g][1] += c
			if r[10].rstrip() == "1":
				parentCountFileRecordLen[g][5] += c
			parentCountFileRecordLen[g][3].append(r)
			parentCountFileRecordLen[g][4] += 1
			if parentCountFileRecordLen[g][4] > 1000:
				fout = open(parentCountFileRecordLen[g][2], 'a')
				w = csv.writer(fout, delimiter='\t', lineterminator='\n')
				try:
					w.writerows(parentCountFileRecordLen[g][3])
				finally:
					fout.close()
				parentCountFileRecordLen[g][3] = []
				parentCountFileRecordLen[g][4] = 0
		#print parentCountFileRecordLen['CTAGCT']
		# flush all records
		for a in parentCountFileRecordLen:
			if parentCountFileRecordLen[a][4] > 0:
				fout = open(parentCountFileRecordLen[a][2], 'a')
				w = csv.writer(fout, delimiter='\t', lineterminator='\n')
				try:
					w.writerows(parentCountFileRecordLen[a][3])
				finally:
					fout.close()
				parentCountFileRecordLen[a][3] = []
				parentCountFileRecordLen[a][4] = 0
	finally:
		fin.close()
	# summary with parent index, count of exact match, count of one-off
	if reportF:
		purity = {}
		for a in parentCountFileRecordLen:
			p = parentCountFileRecordLen[a][0]
			if not p in purity:
				purity[p] = [p, 0, 0, 0, 0]
			if a == p:
				purity[p][1] += parentCountFileRecordLen[a][1]
				purity[p][3] += parentCountFileRecordLen[a][5]
			else:
				if  p == 'ambiguous':
					purity[p][1] += parentCountFileRecordLen[a][1]
					purity[p][3] += parentCountFileRecordLen[a][5]
				else:
					purity[p][2] += parentCountFileRecordLen[a][1]
					purity[p][4] += parentCountFileRecordLen[a][5]
		toWrite = purity.values()
		toWrite.sort()
		fout = open(''.join([outDir, '/', reportF]), 'w')
		w = csv.writer(fout, delimiter='\t')
		print >> fout, "total tags = ", totalTags
		print >> fout, "%s\t%s\t%s\t%s\t%s" % ('Index', 'exactMatch', 'oneOff', 'PfexactMatch', 'PfoneOff')
		w.writerows(toWrite)
		print >> fout, "Ambiguous prefixes: %s" % ' '.join([a for a, p in ambiguousPrefix])
		fout.close()
	return set([parentCountFileRecordLen[p][2] for p in parentCountFileRecordLen])

if __name__ == "__main__":
	import sys
	funcStr = sys.argv[1]
	try:
		func = eval(funcStr)
	except NameError:
		# #python /home/ili/svn/shortReadQuality/bin/splitIndexed.py splitSeqByIndices taglib=s_5_1_0001_qseq.txt report=s_5_1_0001_indexPurity.tbl indices=CTTGTA,TAGCTT,GGCTAC beginning=False indexCol=0 tagCol=9
		print "USAGE: python splitIndexed.py splitSeqByIndices taglibF=, reportF=, indices=, beginning=True, indexCol=None, tagCol=0, countCol=None, chars='ACGT.', oneOff=True, colDelimiter='\t', stripIndex=True"
	else:
		args = {}
		for a in sys.argv[2:]:
			k, v = a.split('=')
			if v.count(',') or k=='indices':
				v = v.split(',')
			elif v == 'True':
				v = True
			elif v == 'False':
				v = False
			elif v=='None':
				v = None
			args[k] = v
		print args
		func(**args)
