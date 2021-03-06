﻿Function Show-BandInfo{
[CmdletBinding()]
Param(
[Parameter(Mandatory="True")][int]$BandNumber)
if(-not (Test-Path ./Bands.txt)){Write-Host "'Bands.txt' not found. Generating it using 'Export-VaspRun' ..." -ForegroundColor Green;
    Export-VaspRun;}
    if($(Test-Path ./Bands.txt)){ #checks if file generated.
    Write-Host "'Bands.txt' exists. Fetching Info ..." -ForegroundColor Yellow;

$data= (Get-Content ./Bands.txt|Select-Object -Skip 1);
$actualIndex=[int]$($BandNumber+3)
$arr =New-Object 'object[]' $data.Count
if($BandNumber -gt 0){
Foreach($i in 0..$(($data.Count)-1)){$arr[$i]=$(($data[$i].split()|Where-Object {$_})[$actualIndex]);}
$max=($arr|Measure-Object -Maximum).Maximum; $min=($arr|Measure-Object -Minimum).Minimum
$maxIndex=[array]::IndexOf($arr,$max)
$minIndex=[array]::IndexOf($arr,$min)
[ordered]@{Minimum="$min"; Maximum="$max";
BandNumber="$BandNumber"; K_min="$minIndex"; K_max="$maxIndex";}
}Else{Write-Host "Try a BandNumber greater than 0." -ForegroundColor Red}
} #test-path block ends
}

Function Find-GapOfBands{
[CmdletBinding()]
Param(
[Parameter(Mandatory="True",Position=0)][int]$UpperBand,[Parameter(Mandatory="True",Position=1)][int]$LowerBand)
if($LowerBand -gt 0 -and $UpperBand -gt 0){
$gap=(Show-BandInfo $UpperBand).Minimum-(Show-BandInfo $LowerBand).Maximum
if($UpperBand -eq $LowerBand){$gap=[Math]::Abs($gap); Set-Clipboard $gap; $gap;
Write-Host "BandWidth: $gap eV of $($UpperBand)th band is copied to clipboard." -ForegroundColor Green;
}Elseif($LowerBand -gt $UpperBand){$gap=[Math]::Abs($gap); Set-Clipboard $gap; $gap;
Write-Host "BandWidth ($UpperBand → $LowerBand): $gap eV is copied to clipboard." -ForegroundColor Green;
}Else{Set-Clipboard $gap; $gap #to make it visible to out-variable
Write-Host "BandGap ($UpperBand → $LowerBand): $gap eV is copied to clipboard." -ForegroundColor Green;}
}Else{Write-Host "Try both BandNumbers greater than 0." -ForegroundColor Red}
}

Function Measure-Distance{
[CmdletBinding()]
Param(
[Parameter(Mandatory="True")][array]$K1B1_K2B2)
if(-not (Test-Path ./Bands.txt)){Write-Host "'Bands.txt' not found. Generating it using 'Export-VaspRun' ..." -ForegroundColor Green;
    Export-VaspRun;}
    if($(Test-Path ./Bands.txt)){ #checks if file generated.
    Write-Host "'Bands.txt' exists. Calculating ..." -ForegroundColor Yellow;
$data= (Get-Content ./Bands.txt|Select-Object -Skip 1);
$First=($data[[int]$K1B1_K2B2[0][0]].split()|Where-Object {$_});
$Second=($data[[int]$K1B1_K2B2[1][0]].split()|Where-Object {$_});
$K1=$First[3];$E1=$First[[int]($K1B1_K2B2[0][1]+3)];
$K2=$Second[3];$E2=$Second[[int]($K1B1_K2B2[1][1]+3)];
$distance=[Math]::Round([Math]::Sqrt([Math]::Pow($($K1-$K2),2)+[Math]::Pow($($E1-$E2),2)),4);
[ordered]@{Point_1=[array]($K1,$E1); Point_2=[array]($K2,$E2); Distance="$distance";} #Output hastable
Write-Host "Distance: $distance [dimensionless] is copied to clipboard." -ForegroundColor Green;
Set-Clipboard $distance; } #test-path block ends
}

Function Get-IndexedPlot{
[CmdletBinding()] Param(
[Parameter(Mandatory="True")][array]$E_Limit,[Parameter()]$xTickDistance=10)  #Get Hashtable from function Get-PlotArguments
$variablesList="E_Limit=[$($E_Limit -join ',')]; distance=$xTickDistance;"
if(-not (Test-Path ./Bands.txt)){Write-Host "'Bands.txt' not found. Generating it using 'Export-VaspRun' ..." -ForegroundColor Green;
    Export-VaspRun;}
    if($(Test-Path ./Bands.txt)){ #checks if file generated.
    Write-Host "'Bands.txt' exists. Plotting ..." -ForegroundColor Yellow;
$systemInfo=(Get-Content ./SysInfo.txt)[0,1]
$plotlines=@'
#====No Edit Below Except Last Few Lines of Legend and File Paths in np.loadtxt('Path/To/File')=====
#====================Loading Packages==============================
import numpy as np; import random; import matplotlib as mpl; import matplotlib.pyplot as plt;
from matplotlib.collections import LineCollection; from matplotlib import colors as mcolors;
from matplotlib import rc; import matplotlib.pyplot as plt; from matplotlib.gridspec import GridSpec;
from matplotlib import collections  as mc
plt.style.use('seaborn'); mpl.rcParams['font.serif'] = "STIXGeneral";
mpl.rcParams['font.family'] = "serif"; mpl.rcParams['mathtext.fontset'] = "stix"
#====================Loading Files===================================
KE=np.loadtxt('./Bands.txt')
K=KE[:,3]; E=KE[:,4:]-E_Fermi; #Seperate KPOINTS and Eigenvalues in memory
yh=max(E_Limit);yl=min(E_Limit);            
#==================================================================
maxEnergy=np.min(E,axis=0); minEnergy=np.max(E,axis=0); #Gets bands in visible energy limits.
max_E=np.max(np.where(maxEnergy <=yh)); min_E=np.min(np.where(minEnergy >=yl))
E=E[:,min_E:max_E+1]; #Updated energy in E_limit 
#=================Plotting============================
plt.figure(figsize=(7,6))
title=r"$\mathrm{%s}$" % (SYSTEM); plt.title(title)
xvalues,indices=[],[];
for i in range(min_E,max_E+1,1):
    value=random.choice(K)
    xvalues.append(value)
    where=np.where(K==value)
    indices.append(where[0][0])
#Full Data Plot
for i in range(np.shape(E)[1]):
    plt.plot(K,E[:,i],linewidth=1)
    plt.text(xvalues[i],E[indices[i],i],str(min_E+i+1),clip_on=True,ha="center", va="center",bbox=dict(boxstyle="circle",ec=None, fc="white",alpha=0.5))
ticks=[K[i] for i in range(0,np.shape(K)[0],distance)]; labels=[i for i in range(0,np.shape(K)[0],distance)]; plt.ylim(yl,yh);
plt.xlabel('Index(k)'); plt.ylabel(r'$E-E_F$');
plt.xticks(ticks,labels,rotation='vertical'); plt.savefig(str('IndexedPlot'+'.pdf')); 
'@
$pythonFileContent=@"
#=================Input Variables=====================
$($variablesList)
$($systemInfo)
$($plotlines)
"@
$pythonFileContent|Set-Content ./IndexedPlot.py
python ./IndexedPlot.py #strat plotting
./IndexedPlot.pdf
} #test-path block ends
}

Function Get-KPath{
    [CmdletBinding()]
    Param([Parameter(Mandatory="True",Position=0)][array]$KptsArray_nCross3,
    [Parameter(Mandatory="True",Position=1)][int]$nPerInterval=25)
    Remove-Item ./KPath.txt -Force -ErrorAction Ignore
    $KPTS=@($KptsArray_nCross3)
    [int]$N=$KPTS.Count; [int]$steps=$nPerInterval
    $steps=$($steps-1); #
    [array]$kpt1=$KPTS[0]
    for($i=1;$i -lt $N;$i++){
    [array]$kpt2=$KPTS[$i]
    $values=($kpt1,$kpt2)
    $dx=($values[1][0]-$values[0][0])/$steps
    $dy=($values[1][1]-$values[0][1])/$steps
    $dz=($values[1][2]-$values[0][2])/$steps
    $point= "$("{0,8:n4}" -f $values[0][0])    $("{0,8:n4}" -f $values[0][1])     $("{0,8:n4}" -f $values[0][2])       0"
    $point|Add-Content ./KPath.txt
    $sum=$values[0][0],$values[0][1],$values[0][2]
    for($x=1; $x -le ($steps-1); $x++){
    $sum[0]=[Math]::Round($dx+$sum[0],5); $sum[0]="{0,8:n4}" -f  $($sum[0])
    $sum[1]=[Math]::Round($dy+$sum[1],5);  $sum[1]="{0,8:n4}" -f  $($sum[1])
    $sum[2]=[Math]::Round($dz+$sum[2],5); $sum[2]="{0,8:n4}" -f $($sum[2])
    $point= "$($sum[0])    $($sum[1])     $($sum[2])     $("{0,8:n4}" -f 0)"
    $point|Add-Content ./KPath.txt
    } $kpt1=$kpt2 #switch
    $point= "$("{0,8:n4}" -f $values[1][0])    $("{0,8:n4}" -f $values[1][1])     $("{0,8:n4}" -f $values[1][2])       0"
    $point|Add-Content ./KPath.txt
    }
    Write-Host "File [KPath.txt] created. Output copied to clipboard." -ForegroundColor DarkCyan
    Set-Clipboard (Get-Content ./KPath.txt)
    }

Function Format-DataInFile{
    [Cmdletbinding()]
    Param([Parameter(Mandatory="True",Position=0)][string]$InputFile,
    [Parameter()][switch]$ViewAsExcel,
    [Parameter()][switch]$DispalyFewColumns,
    [Parameter()][array]$SelectColumns,
    [Parameter()][string]$CommentStartsWith='#')
    $objects=[System.Collections.ArrayList]@()
    $file=(Get-Content $InputFile|Where-Object {$_ -notmatch $CommentStartsWith})#.replace(',','')
    $head=(Get-Content $InputFile)[0].replace('#','!').replace('[','').replace(']','').Split()|Where-Object {$_}
    $j=0; $h_s=@()
    Foreach($item in $file){
    [array]$values=$item.Split()|Where-Object {$_}
    $myObject = New-Object System.Object
    $myObject | Add-Member -type NoteProperty -name Index -Value $j
    $j+=1
    if($DispalyFewColumns.IsPresent){$selected=@($SelectColumns)
    }Else{$selected=1..$values.Count}
    Foreach($i in $selected){
    $value=$values[$i-1]; [string]$name=$head[$i-1];
    $myObject | Add-Member -type NoteProperty -name $name -Value $value
    }
    [void]$objects.Add($myObject)
    }
    if($ViewAsExcel.IsPresent){$objects |Out-GridView -PassThru -Title "ExcelView of $InputFile"}
    Else{$objects}
    }
#Below function works only if JupyterDashbaord or Dash App is used before.
Function Import-Numbers($FolderPath='.'){
    $filedata=Get-Content $FolderPath/Result.txt
    $array=[ordered]@{} #ordered hashtable
    $filedata|ForEach-Object{$item=$_.Split().Trim()|Where-Object{$_}; $array.Add("$($item[0])","$($item[1])")}
    $array #return ordered hashtable
    }
Export-ModuleMember -Function 'Show-BandInfo'
Export-ModuleMember -Function 'Find-GapOfBands'
Export-ModuleMember -Function 'Measure-Distance'
Export-ModuleMember -Function 'Get-IndexedPlot'
Export-ModuleMember -Function 'Get-KPath'
Export-ModuleMember -Function 'Format-DataInFile'
Export-ModuleMember -Function 'Import-Numbers'