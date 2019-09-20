current_dir = "/home/kouui/cloud_computing/experiment/test_saving_with_idl_bridge/"

n_loop = 9

print, "---- without bridge ----"

TIC, /PROFILER
clock = TIC()

for i = 0, n_loop-1 do begin
    
    arr1 = replicate(double(i), 100, 1024, 1024)
    wait, 2
    
    filename = current_dir + "arr1.sav"
    save, arr1, filename=filename

    TOC, clock, REPORT=interimReport	

endfor

TOC, REPORT=finalReport


;--------------------------------------
end
