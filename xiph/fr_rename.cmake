# Included at the end of the top-level project() command of the ogg and opus
# builds (via -DCMAKE_PROJECT_INCLUDE). Renames the shared library targets so
# both the output file name and the ELF SONAME become libfr_ogg.so /
# libfr_opus.so. This avoids clashes with other plugins that also ship
# libogg/libopus (e.g. flutter_soloud) and, crucially, makes the DT_NEEDED
# entries recorded in libflutter_recorder.so match the file names that are
# actually packaged into the APK.
function(_fr_rename_targets)
  foreach(t ogg opus)
    if(TARGET ${t})
      set_target_properties(${t} PROPERTIES OUTPUT_NAME fr_${t})
    endif()
  endforeach()
endfunction()

# Defer the rename to the end of the top-level directory scope, when all
# targets have been created.
cmake_language(DEFER CALL _fr_rename_targets)
