Chromatogram Applet, Release 2.5, 07/28/2006
(modified by Joseph Roy Santos, GSC)

- Added an slider bar on the left to allow for scaling the graph up. It supports 1x (bottom of slider, default) to 20x (top of slider).
- Added an option to complement the trace. This will start the trace from the end, and all of the base pairs will be complemented (A -> T, C -> G, and so on)
- moved the statistics to a place above the trace canvas. This is to prevent the graph from obscuring them when it is scaled up.

Chromatogram Applet

  This java applet was prossibly modified by Oliver Lee to read
  additional types of trace files for the GSC. There may also have
  been other features added. Or maybe not.

  To install this applet, you need to put all the .class files into
  a .jar named ChromatogramViewer.jar, and then place the .jar file
  in the top level of your htdocs directory.

  
Chromatogram Applet, Release 1, 6/30/96
by Eugen Buehler
---------------------------------------------------------------------------
This software is free, and may be distributed by any means.
The author is not responsible for any damage or losses due to the use of this software.
No warranty or guarantee is made for this software.
No part of this software may be sold or included in any commercial package without
the author's written consent.
This software may be used only for good, never for evil.
---------------------------------------------------------------------------

The files included in this archive will allow you to make chromatograms viewable within your web pages.  The Chromatogram Applet can read SCF files (version 2 or 3) and ABI sample files.   Java source files have been included for those of you that are into that sort of thing.

Step by Step:
0. (JDP was here) type "javac *.java" (if you are on a UNIX box) to compile

1.  Move all seven files in the archive with the ".class" postfix into the directory with your HTML files.  (ABIChromatogram.class, Chromatogram.class, ChromatogramApplet.class, TaggedRecord.class, ChromatogramViewer.class, ChromatogramCanvas.class, and SCFChromatogram.class).

2.  Put an ABI sample file or SCF file into the  same HTML directory.

3.  Within an HTML document, place an <APPLET> tag.  It should look something like this:

<applet code="ChromatogramApplet.class" width=400 height=200>
<param name="file" value="Your_File_Name_Here">
<H2>If you see this text, it means that you are not using a java capable browser.
Sorry!</H2>
</applet>

Width and height can be adjusted to suit your purposes (although making these too small could result in errors).   Change Your_File_Name_Here to the name of your ABI or SCF file.   This should about do it.  Anyone who views the page with a non-java capable browser will see the message between the applet tags.

---------------------------------------------------------------------------
Send questions, comments, requests, and abject praise to:
Eugen Buehler, snafu@telerama.lm.com

