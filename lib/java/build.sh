#!/bin/sh

#Compile *.java files to *.class files.
echo 'Compiling *.java files to *.class files...'
/home/achan/jdk/bin/javac -deprecation Chromatogram_Applet/*.java

#Put *.class files into a single Java archive file.
echo 'Putting *.class files into ChromatogramViewer.jar...'
/home/achan/jdk/bin/jar cvf Chromatogram_Applet/ChromatogramViewer.jar Chromatogram_Applet/*.class

#Remove all the *.class files generated.
echo 'Deleting *.class files...'
rm -f Chromatogram_Applet/*.class

#Move the java archive file into /www/applets/.
echo 'Moving ChromatogramViewer.jar to ../../www/applets/...'
mv -f Chromatogram_Applet/ChromatogramViewer.jar ../../www/applets/
