current_dir = "/home/kouui/cloud_computing/experiment/test_saving_with_idl_bridge/"

n_loop = 9
n_cpu = 3

bridge = objarr(n_cpu)
for i = 0, n_cpu-1 do bridge[i] = obj_new("IDL_IDLBridge")


print, "---- with bridge ----"

TIC, /PROFILER
clock = TIC()

for i = 0, n_loop-1 do begin
    
    arr1 = replicate(double(i), 100, 1024, 1024)
    wait, 2

    arr2 = arr1 ; buffer
    
    bi = i mod n_cpu
    print, "using bridge ", bi
    bridge[bi]->SetVar, "arr3", arr2
    bridge[bi]->SetVar, "filename", current_dir + "arr3.sav"
    bridge[bi]->Execute, "save, arr3, filename=filename", /nowait

    ;save, arr2, filename="kouui/cloud_computing/experiment/test_saving_with_idl_bridge/arr2.sav"

    TOC, clock, REPORT=interimReport	

endfor

TOC, REPORT=finalReport


;--------------------------------------
end
