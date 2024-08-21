
all: abrx.mex4 cabc2rf.mex4 b2a.mex4 npoly.mex4 b2rf.mex4 minpeakrf.mex4 

abrx.mex4: abrx.c 
	cmex -O abrx.c -lm

cabc2rf.mex4: cabc2rf.c cabc2rf.code.c
	cmex -O -v3.5 cabc2rf.c cabc2rf.code.c -lm

b2a.mex4: b2a.c b2a.code.c four1.c 
	cmex -O -v3.5 b2a.c b2a.code.c four1.c -lm

npoly.mex4: npoly.c npoly.code.c four1.c
	cmex -O -v3.5 npoly.c npoly.code.c four1.c -lm

b2rf.mex4: b2rf.c b2a.code.c cabc2rf.code.c four1.c 
	cmex -O -v3.5 b2rf.c b2a.code.c cabc2rf.code.c four1.c -lm

minpeakrf.mex4: minpeakrf.c npoly.code.c b2a.code.c cabc2rf.code.c four1.c 
	cmex -O -v3.5 minpeakrf.c npoly.code.c b2a.code.c cabc2rf.code.c four1.c -lm

