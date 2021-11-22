#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function WaffleMaker(aa,anb,bb,col,iter)
	Variable aa, anb, bb, col, iter
	aa = round(aa)
	anb = round(anb)
	bb = round(bb)
	col = round(col)
	iter = round(iter)
	Variable total = aa + anb + bb
	Variable row = ceil(total / col)
	
	// xy coords for waffle plot
	Make/O/N=(row * col,2) $("waffleXY_" + num2str(iter))
	Wave/Z wXY = $("waffleXY_" + num2str(iter))
	wXY[][0] = mod(p,col) //x
	wXY[][1] = floor(p / col) //x
	// set colors for waffle plot
	Make/O/N=(row * col) $("waffleZ_" + num2str(iter)) = 0
	Wave/Z wZ = $("waffleZ_" + num2str(iter))
	if(aa != 0)
		wZ[0,aa - 1] = 1 // bit 0 set
	endif
	if(anb != 0)
		wZ[aa,aa + anb - 1] = 3 // bit 0 and bit 1 set
	endif
	if(bb != 0)
		wZ[aa + anb,total - 1] = 2 // bit 1 set
	endif
	// make colorWave - easier to write in other orientation then transpose
	Make/O/N=(3,4) colorWave = {{230,230,230},{0,166,81},{237,28,36},{255,199,32}}
	colorWave *= 257 // convert to 16-bit
	MatrixTranspose colorWave
	
	String plotName = "wafflePlot" + "_" + num2str(iter)
	KillWindow/Z $plotName
	Display/N=$plotName wXY[][1] vs wXY[][0]
	ModifyGraph/W=$plotName mode=3,marker=19
	SetAxis/W=$plotName left row - 0.5,-0.5
	SetAxis/W=$plotName bottom -0.5, col - 0.5
	ModifyGraph/W=$plotName height={Plan,1,left,bottom}
	ModifyGraph/W=$plotName msize=6
	ModifyGraph/W=$plotName noLabel=2,axThick=0
	ModifyGraph/W=$plotName margin=2
	ModifyGraph/W=$plotName zColor($NameOfWave(wXY))={wZ,*,*,cindexRGB,0,colorWave}
End