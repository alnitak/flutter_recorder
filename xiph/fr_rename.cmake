# Included at the end of the top-level project() command of the ogg, opus,
# and speexdsp builds (via -DCMAKE_PROJECT_INCLUDE). Renames the shared library
# targets so both the output file name and the internal library name (ELF SONAME
# on Linux/Android, DLL export name and import library target on Windows) become
# fr_<lib>. This avoids clashes with other plugins that also ship these libraries
# (such as flutter_soloud).
function(_fr_rename_targets)
  foreach(t ogg opus speexdsp)
    if(TARGET ${t})
      set_target_properties(${t} PROPERTIES OUTPUT_NAME fr_${t})
    endif()
  endforeach()
endfunction()

# On Windows, win32/ogg.def hardcodes "LIBRARY ogg", which causes MSVC link.exe
# to record "ogg.dll" in the DLL export table and generated import library (fr_ogg.lib),
# overriding CMake's OUTPUT_NAME fr_ogg. Patch it to "LIBRARY fr_ogg".
if(WIN32 AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/win32/ogg.def")
  file(READ "${CMAKE_CURRENT_SOURCE_DIR}/win32/ogg.def" _ogg_def)
  string(REPLACE "LIBRARY ogg" "LIBRARY fr_ogg" _ogg_def "${_ogg_def}")
  file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/win32/ogg.def" "${_ogg_def}")
endif()

# Defer the rename to the end of the top-level directory scope, when all
# targets have been created.
cmake_language(DEFER CALL _fr_rename_targets)
