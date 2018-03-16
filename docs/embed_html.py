#!/usr/bin/env python
# -*- coding: utf-8 vi:noet
# Embed a Matlab-generated HTML file into .rst

import sys, os, re, io, shutil, argparse

if sys.hexversion < 0x03000000:
	from HTMLParser import HTMLParser
else:
	from html.parser import HTMLParser

class MyHTMLParser(HTMLParser):
	"""
	Ad-hoc Matlab HTML parser that extracts the useful HTML payload,
	insertable in an existing HTML document.

	It looks like everything in the first <div> is desired.
	The image content is copied to the destination directory.
	"""
	def __init__(self, out, dstdir, srcdir):
		HTMLParser.__init__(self)
		self._out = out
		self._divlevel = 0
		self._srcdir = srcdir
		self._dstdir = dstdir

	def handle_starttag(self, tag, attrs):
		if tag == "div":
			self._divlevel += 1

		if tag == "img":
			dattrs = dict(attrs)
			src = dattrs["src"]
			srcpath = os.path.join(self._srcdir, src)
			dstpath = os.path.join(self._dstdir, "_static", src)
			if os.path.exists(srcpath):
				shutil.copy(srcpath, dstpath)
				dattrs["src"] = "_static/%s" % src
				attrs = [ x for x in dattrs.items() ]

		if self._divlevel > 0:
			self._out.write(("<%s %s>" % (tag, " ".join(['%s="%s"' % (k, v) for k, v in attrs]))))

	def handle_endtag(self, tag):
		if self._divlevel > 0:
			self._out.write(("</%s>" % tag))
		if tag == "div":
			self._divlevel -= 1

	def handle_data(self, data):
		if self._divlevel > 0:
			self._out.write(data)


if __name__ == "__main__":

	dst = sys.argv[1]
	dstdir = os.path.dirname(dst)
	src = sys.argv[2]
	srcdir = os.path.dirname(src)
	title = sys.argv[3]

	with io.open(dst, "wb") as fo:

		fo.write(title.encode())
		fo.write(b"\n")
		fo.write(b"=" * len(title))
		fo.write(b"\n")
		fo.write(b"\n")
		fo.write(b".. raw:: html\n")
		fo.write(b"\n   \n")

		with io.open(src, "rb") as fi:
			data = fi.read().decode("utf-8")

			# This is taken from the Matlab HTML stylesheet, but scoped
			sbuf = io.StringIO()
			sbuf.write(u"""<style type="text/css">
.content { font-size:1.0em; line-height:140%; padding: 20px; }
.content p { padding:0px; margin:0px 0px 20px; }
.content img { padding:0px; margin:0px 0px 20px; border:none; }
.content p img, pre img, tt img, li img, h1 img, h2 img { margin-bottom:0px; }
.content ul { padding:0px; margin:0px 0px 20px 23px; list-style:square; }
.content ul li { padding:0px; margin:0px 0px 7px 0px; }
.content ul li ul { padding:5px 0px 0px; margin:0px 0px 7px 23px; }
.content ul li ol li { list-style:decimal; }
.content ol { padding:0px; margin:0px 0px 20px 0px; list-style:decimal; }
.content ol li { padding:0px; margin:0px 0px 7px 23px; list-style-type:decimal; }
.content ol li ol { padding:5px 0px 0px; margin:0px 0px 7px 0px; }
.content ol li ol li { list-style-type:lower-alpha; }
.content ol li ul { padding-top:7px; }
.content ol li ul li { list-style:square; }
.content pre, code { font-size:11px; }
.content tt { font-size: 1.0em; }
.content pre { margin:0px 0px 20px; }
.content pre.codeinput { padding:10px; border:1px solid #d3d3d3; background:#f7f7f7; overflow-x:scroll}
.content pre.codeoutput { padding:10px 11px; margin:0px 0px 20px; color:#4c4c4c; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word -wrap: break-word;}
.content pre.error { color:red; }
.content @media print { pre.codeinput, pre.codeoutput { word-wrap:break-word; width:100%; } }
.content span.keyword { color:#0000FF }
.content span.comment { color:#228B22 }
.content span.string { color:#A020F0 }
.content span.untermstring { color:#B20000 }
.content span.syscmd { color:#B28C00 }
.content .footer { width:auto; padding:10px 0px; margin:25px 0px 0px; border-top:1px dotted #878787; font-size:0.8em; line-height:140%; font-style:italic; color:#878787; text-align:left; float:none; }
.content .footer p { margin:0px; }
.content .footer a { color:#878787; }
.content .footer a:hover { color:#878787; text-decoration:underline; }
.content .footer a:visited { color:#878787; }
.content table th { padding:7px 5px; text-align:left; vertical-align:middle; border: 1px solid #d6d4d4; font-weight:bold; }
.content table td { padding:7px 5px; text-align:left; vertical-align:top; border:1px solid #d6d4d4; }
::-webkit-scrollbar {
    -webkit-appearance: none;
    width: 4px;
    height: 5px;
   }

   ::-webkit-scrollbar-thumb {
    border-radius: 5px;
    background-color: rgba(0,0,0,.5);
    -webkit-box-shadow: 0 0 1px rgba(255,255,255,.5);
   }
</style>""")

			parser = MyHTMLParser(sbuf, dstdir, srcdir)
			parser.feed(data)

			for line in sbuf.getvalue().splitlines():
				fo.write(("   %s\n" % line).encode("utf-8"))

		fo.close()
