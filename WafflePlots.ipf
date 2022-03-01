#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#include "PXPUtils"
#include <ColorWaveEditor>

// Waffle Plots
// Show proportions in a waffle style plot instead of using a Venn diagram
// Intended for use to display colocalisation data - from two channels
// Limitations:
//	Uses circles only (any shape is possible but requires more development)
//	Shows two groups and their intersection only (hard coded to color green/yellow/red)

//	Example usage:
//WaffleMaker(33,12,62,9,0)
//WaffleMaker(11,1,57,9,1)
//WaffleMaker(0,0,55,8,2)
//EqualiseWaffles() // makes all waffles the same size
//PXPUtils#MakeTheLayouts("wafflePlot",0,6, alphaSort = 1, saveIt = 0)

////////////////////////////////////////////////////////////////////////
// Menu items
////////////////////////////////////////////////////////////////////////
Menu "Macros"
	"Equalise Waffles", /Q, EqualiseWaffles()
	Submenu "Waffle Colors"
		Submenu "Presets"
			"Green-Yellow-Red", /Q, RemakeColorWave("GYR")
			"Green-Cyan-Magenta", /Q, RemakeColorWave("GCM")
			"Tol 1", /Q, RemakeColorWave("Tol1")
			"Tol 2", /Q, RemakeColorWave("Tol2")
			"Wong 1", /Q, RemakeColorWave("Wong1")
			"Wong 2", /Q, RemakeColorWave("Wong2")
		End
		"User Selection", /Q, UserControlForRecoloring()
		"Restore Last Color Scheme", /Q, RestoreLast()
	End
	Submenu "Waffle Symbols"
		"Circles Filled", /Q, ChangeSymbols(19)
		"Circles Open", /Q, ChangeSymbols(8)
		"Squares Filled", /Q, ChangeSymbols(16)
		"Specify...", /Q, SpecifySymbols()
		"Change Size", /Q, SpecifySize()
	End
End


////////////////////////////////////////////////////////////////////////
// Master functions and wrappers
////////////////////////////////////////////////////////////////////////

/// @param	aa	Variable	number of green spots
/// @param	anb	Variable	number of yellow spots (intersection/colocalisation)
///	@param	bb	Variable	number of red spots
///	@param	col	Variable	number of columns (rows are set by total number of spots)
///	@param	iter	Int		Plot number (allows for recreating/overwriting)
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
	wXY[][1] = floor(p / col) //y
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
	// assemble colorWave if not already present
	WAVE/Z colorWave
	if(!WaveExists(colorWave))
		// make colorWave - easier to write in other orientation then transpose
		Make/O/N=(3,4) colorWave = {{230,230,230},{0,166,81},{237,28,36},{255,199,32}}
		colorWave *= 257 // convert to 16-bit
		MatrixTranspose colorWave
	endif
	
	DisplayWaffle("wafflePlot" + "_" + num2str(iter),wXY,wZ)
End

Function DisplayWaffle(plotName,xyWave,zWave)
 	String plotName
 	Wave xyWave, zWave
 	
 	WAVE/Z colorWave
 	WaveStats/RMD=[][0]/Q xyWave
 	Variable col = V_max + 1
 	WaveStats/RMD=[][1]/Q xyWave
 	Variable row = V_max + 1
	KillWindow/Z $plotName
	Display/N=$plotName xyWave[][1] vs xyWave[][0]
	ModifyGraph/W=$plotName mode=3,marker=19
	SetAxis/W=$plotName left row - 0.5,-0.5
	SetAxis/W=$plotName bottom -0.5, col - 0.5
	ModifyGraph/W=$plotName height={Plan,1,left,bottom}
	ModifyGraph/W=$plotName msize=4
	ModifyGraph/W=$plotName noLabel=2,axThick=0
	ModifyGraph/W=$plotName margin=2
	ModifyGraph/W=$plotName zColor($NameOfWave(xyWave))={zWave,*,*,cindexRGB,0,colorWave}
End

Function EqualiseWaffles()
	// find size of biggest waffle
	String wList = WaveList("waffleXY*",";","")
	Variable nWaves = ItemsInList(wList)
	Variable maxRow = 0, maxCol = 0, row, col
	
	Variable i
	
	for(i = 0; i < nWaves; i += 1)
		WaveStats/RMD=[][0]/Q $StringFromList(i, wList)
 		maxCol = max(maxCol,V_max + 1)
	 	WaveStats/RMD=[][1]/Q $StringFromList(i, wList)
	 	maxRow = max(maxRow,V_max + 1)
	endfor
	
	String wName
	
	for(i = 0; i < nWaves; i += 1)
		wName = StringFromList(i, wList)
		Wave w = $wName
		WaveStats/RMD=[][0]/Q w
 		col = V_max + 1
	 	WaveStats/RMD=[][1]/Q w
	 	row = V_max + 1
	 	if(col < maxCol || row < maxRow)
	 		ResizeWaffle(w,maxRow,maxCol)
	 	endif
	endfor
End

Function ResizeWaffle(m0,row,col)
	Wave m0
	Variable row, col
	
	if(DimSize(m0,0) > row * col)
		Print NameOfWave(m0), "too many points"
		return -1
	endif
	
	String xyWaveName = NameOfWave(m0)
	Make/O/N=(row * col, 2) $xyWaveName
	Wave m0 = $xyWaveName
	m0[][0] = mod(p,col) //x
	m0[][1] = floor(p / col) //y
	
	String zWaveName = ReplaceString("waffleXY_",xyWaveName,"waffleZ_")
	Wave zW = $zWaveName
	Duplicate/O/FREE zW, tempW
	Make/O/N=(row * col) $zWaveName = 0
	Wave zW = $zWaveName
	zW[0,DimSize(tempW,0) - 1] = tempW[p]
	DisplayWaffle(ReplaceString("waffleXY_",xyWaveName,"wafflePlot_"),m0,zW)
	
	return 0
End

////////////////////////////////////////////////////////////////////////
// Utility functions
////////////////////////////////////////////////////////////////////////
Function RemakeColorWave(colorStr)
	String colorStr
	
	SetDataFolder root:
	strswitch(colorStr)
		case "GYR" :
			Make/O/N=(3,4) colorWave = {{230,230,230},{0,166,81},{237,28,36},{255,199,32}}
			break
		case "GCM" :
			Make/O/N=(3,4) colorWave = {{230,230,230},{0,166,81},{193,0,102},{4,119,146}}
			break
		case "Tol1" :
			Make/O/N=(3,4) colorWave = {{187,187,187},{34,136,51},{238,102,119},{204,187,68}}
			break
		case "Tol2" :
			Make/O/N=(3,4) colorWave = {{187,187,187},{34,136,51},{170,51,119},{102,204,238}}
			break
		case "Wong1" :
			//https://www.nature.com/articles/nmeth.1618
			// Bluish Green, Yellow, Vermillion
			Make/O/N=(3,4) colorWave = {{230,230,230},{0,158,115},{213,94,0},{240,228,66}}
			break
		case "Wong2" :
			// Bluish green, Reddish purple, Sky blue
			Make/O/N=(3,4) colorWave = {{230,230,230},{0,158,115},{204,121,167},{86,180,233}}
			break
	endswitch
	
	colorWave *= 257 // convert to 16-bit
	MatrixTranspose colorWave
End

Function UserControlForRecoloring()
	SetDataFolder root:
	WAVE/Z colorWave = root:colorWave
	if(!WaveExists(colorWave))
		DoAlert 0, "3-column colorwave required"
		return -1
	endif
	Duplicate/O colorWave, colorWave_BKP
	// present dialog to work on recoloring
	CWE_MakeClientColorEditor(colorWave, 0, 65535, "Edit Colors","ColorWave","RecolorAllPlots")
	
	return 0
End

Function RestoreLast()
	SetDataFolder root:
	WAVE/Z colorWave, colorWave_BKP
	if(!WaveExists(colorWave))
		DoAlert 0, "3-column colorwave required"
		return -1
	endif
	if(!WaveExists(colorWave_BKP))
		DoAlert 0, "No backup colorwave found"
		return -1
	endif
	Duplicate/O colorWave_BKP,colorWave
	
	return 0
End

Function ChangeSymbols(sym)
	Variable sym
	
	String WindowList = WinList("wafflePlot*", ";", "WIN:1")
	Variable nWindows = ItemsInList(WindowList)
	
	Variable i
	
	for(i = 0; i < nWindows; i += 1)
		ModifyGraph/W=$(StringFromList(i,WindowList)) marker=sym
	endfor
	DoWindow/F/Z allWafflePlotLayout
End

Function SpecifySymbols()
	Variable symbolNum = 19
	Prompt symbolNum, "Symbol Number"
	DoPrompt "Enter new symbol", symbolNum
	if(V_Flag)
		return -1
	endif
	ChangeSymbols(symbolNum)
	DoWindow/F/Z allWafflePlotLayout
End

Function ChangeSize(size)
	Variable size
	
	String WindowList = WinList("wafflePlot*", ";", "WIN:1")
	Variable nWindows = ItemsInList(WindowList)
	
	Variable i
	
	for(i = 0; i < nWindows; i += 1)
		ModifyGraph/W=$(StringFromList(i,WindowList)) msize=size
	endfor
	DoWindow/F/Z allWafflePlotLayout
End

Function SpecifySize()
	Variable sizeNum = 4
	Prompt sizeNum, "Size (default = 4, 0 for Auto)"
	DoPrompt "Enter new size", sizeNum
	if(V_Flag)
		return -1
	endif
	ChangeSize(sizeNum)
	DoWindow/F/Z allWafflePlotLayout
End