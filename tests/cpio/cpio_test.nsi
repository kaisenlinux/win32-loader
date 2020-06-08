; Licensed under the zlib/libpng license (same as NSIS)

; cpio test runner
; Run installer with the following arguments
;  /IN=<file> /OUT=<cpio archive> /RESULT=<result file>

Unicode True
Name cpio
RequestExecutionLevel user

!include FileFunc.nsh

!insertmacro GetParameters
!insertmacro GetOptions

!include include/cpio.nsh
${CPIO_Write}

Page InstFiles

Var Arguments

Section GenerateCPIO
  StrCpy $0 ${ERROR_WRITE_FAULT}
  ${GetOptions} $Arguments "/IN=" $1
  ${GetOptions} $Arguments "/OUT=" $2
  ${GetOptions} $Arguments "/RESULT=" $3
  FileOpen $4 "$3" w
  ${IfNot} ${Errors}
    FileOpen $5 "$2" w
    ${IfNot} ${Errors}
      ${CPIO_Write} $5 $1 $0
      ${If} $0 == 0
        ${CPIO_Write} $5 "" $0
      ${EndIf}
      FileClose $5
    ${EndIf}
    FileWrite $4 "$0$\n"
    FileClose $4
  ${EndIf}
SectionEnd

Function .onInit
  InitPluginsDir
  ${GetParameters} $Arguments
  SetOutPath "$EXEDIR"
FunctionEnd
