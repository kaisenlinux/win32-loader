; Licensed under the zlib/libpng license (same as NSIS)

!ifndef CPIO_INCLUDED
!define CPIO_INCLUDED

!include include\stdmacros.nsh
!include LogicLib.nsh
!include Win\WinError.nsh

!define CPIO_PREFIX "CPIO_"
!define CPIO_UNFUNC "un."

!ifndef CPIO_BUFFER_SIZE
!define CPIO_BUFFER_SIZE 262144
!endif

!define CPIO_BY_HANDLE_FILEINFO_SIZE 52

!define CPIO_MODE_REGULAR_FILE 0x8000
!define CPIO_MODE_USER_WRITE   0x0080
!define CPIO_MODE_USER_READ    0x0100
!define CPIO_MODE_GROUP_WRITE  0x0010
!define CPIO_MODE_GROUP_READ   0x0020
!define CPIO_MODE_OTHER_WRITE  0x0002
!define CPIO_MODE_OTHER_READ   0x0004
!define /math CPIO_MODE_DEFAULT_FILE ${CPIO_MODE_REGULAR_FILE} + ${CPIO_MODE_USER_WRITE}
!define /redef /math CPIO_MODE_DEFAULT_FILE ${CPIO_MODE_DEFAULT_FILE} + ${CPIO_MODE_USER_READ}
!define /redef /math CPIO_MODE_DEFAULT_FILE ${CPIO_MODE_DEFAULT_FILE} + ${CPIO_MODE_GROUP_READ}
!define /redef /math CPIO_MODE_DEFAULT_FILE ${CPIO_MODE_DEFAULT_FILE} + ${CPIO_MODE_OTHER_READ}

!define CPIO_NEWC_MAGIC "070701"

!define CPIO_FILETIME_TICKS_PER_SEC 10000000
!define CPIO_SEC_TO_UNIX_EPOCH 11644473600

!define CPIO_FUNCDEF \
  `!insertmacro STDMACROS_FUNCDEF ${CPIO_PREFIX}`
!define CPIO_FUNCINC \
  `!insertmacro STDMACROS_FUNCINC ${CPIO_PREFIX}`
!define CPIO_FUNCPROLOG \
  `!insertmacro STDMACROS_FUNCPROLOG ${CPIO_PREFIX}`

; ${CPIO_Write} filehandle filename result
${CPIO_FUNCDEF} Write
!macro CPIO_Write_Call UN FILEHANDLE FILENAME RESULT
  Push ${FILEHANDLE}
  Push "${FILENAME}"
  Call `${UN}${CPIO_PREFIX}Write`
  Pop ${RESULT}
!macroend

!macro CPIO_Write UN
; Write the file with the provided name to the cpio archive represented
; by its filehandle
; Parameters:
;   filehandle - cpio archive file handle
;   filename - name of file to be added to cpio archive
; Return value:
;   0 if successful otherwise error code
${CPIO_FUNCPROLOG} "${UN}" Write
  System::Store 'S'
  Pop $4
  Pop $1

  StrCpy $0 ${ERROR_OUTOFMEMORY}
  System::Alloc ${CPIO_BY_HANDLE_FILEINFO_SIZE}
  Pop $3
  ${If} $3 P<> 0
    StrCpy $0 0
    StrCpy $5 0
    ${If} $4 != ""
      ClearErrors
      FileOpen $2 "$4" r
      ${If} ${Errors}
        StrCpy $0 ${ERROR_FILE_NOT_FOUND}
      ${Else}
        System::Call "kernel32::GetFileSize(p r2, p 0) i.r5"
        System::Call "kernel32::GetFileInformationByHandle(p r2, p r3) i.r6?e"
        Pop $0
        ${If} $6 != 0
          StrCpy $0 0
        ${EndIf}
      ${EndIf}
    ${Else}
      StrCpy $2 ""
      StrCpy $4 "TRAILER!!!"
    ${EndIf}
    ${If} $0 == 0
      StrCpy $6 ""
      FileWrite $1 ${CPIO_NEWC_MAGIC}
      ; Use nFileIndexLow as inode
      System::Call "*$3(&v48,&i4 .r0)"
      IntFmt $0 "%08X" $0
      StrCpy $6 "$6$0"
      ; File mode
      ${If} $2 != ""
        StrCpy $0 ${CPIO_MODE_DEFAULT_FILE}
      ${Else}
        StrCpy $0 0
      ${EndIf}
      IntFmt $0 "%08X" $0
      StrCpy $6 "$6$0"
      ; User identifier
      IntFmt $0 "%08X" 0
      StrCpy $6 "$6$0"
      ; Group identifier
      StrCpy $6 "$6$0"
      ; Number of links
      System::Call "*$3(&v40,&i4 .r0)"
      IntFmt $0 "%08X" $0
      StrCpy $6 "$6$0"
      ; Last modified time
      ${If} $2 != ""
        System::Call "*$3(&v20,l .r0)"
        ; Convert file to unix time
        System::Int64Op $0 / ${CPIO_FILETIME_TICKS_PER_SEC}
        Pop $0
        System::Int64Op $0 - ${CPIO_SEC_TO_UNIX_EPOCH}
        Pop $0
      ${Else}
        StrCpy $0 0
      ${EndIf}
      IntFmt $0 "%08X" $0
      StrCpy $6 "$6$0"
      ; Size of file
      IntFmt $0 "%08X" $5
      StrCpy $6 "$6$0"
      ; Device major and minor identifier
      System::Call "*$3(&v28,&i4 .r0)"
      Push $0
      IntOp $0 $0 & 0xFF
      IntFmt $0 "%08X" $0
      StrCpy $6 "$6$0"
      Pop $0
      IntOp $0 $0 >>> 8
      IntFmt $0 "%08X" $0
      StrCpy $6 "$6$0"
      ; Special device major and minor identifier
      IntFmt $0 "%08X" 0
      StrCpy $6 "$6$0"
      StrCpy $6 "$6$0"
      ; Size of name
      StrLen $0 $4
      IntOp $0 $0 + 1
      Push $0 ; Save name length
      IntFmt $0 "%08X" $0
      StrCpy $6 "$6$0"
      ; Check
      IntFmt $0 "%08X" 0
      StrCpy $6 "$6$0"
      FileWrite $1 "$6"
      ; Name of file
      FileWrite $1 $4
      FileWriteByte $1 0
      ; Padding
      Pop $0 ; Restore name length
      IntOp $0 2 - $0
      IntOp $0 $0 & 3
      ${While} $0 > 0
        FileWriteByte $1 0
        IntOp $0 $0 - 1
      ${EndWhile}
      ${If} ${Errors}
        StrCpy $0 ${ERROR_WRITE_FAULT}
      ${ElseIf} $2 != ""
        System::Alloc ${CPIO_BUFFER_SIZE}
        Pop $4
        ${If} $4 P<> 0
          Push $5 ; Save file size
          ${Do}
            System::Call "kernel32::ReadFile(p r2, p r4, i ${CPIO_BUFFER_SIZE}, *i .r5, p 0) i.r6?e"
            ${If} $6 != 0
              Pop $0
              System::Call "kernel32::WriteFile(p r1, p r4, i r5, *i .r5, p 0) i.r6?e"
              ${If} $6 == 0
                StrCpy $5 0
              ${EndIf}
            ${EndIf}
            Pop $0
          ${LoopUntil} $5 < ${CPIO_BUFFER_SIZE}
          Pop $5 ; Restore file size
          ${If} $6 != 0
            ; Padding
            IntOp $0 4 - $5
            IntOp $0 $0 & 3
            ${While} $0 > 0
              FileWriteByte $1 0
              IntOp $0 $0 - 1
            ${EndWhile}
            ${If} ${Errors}
              StrCpy $0 ${ERROR_WRITE_FAULT}
            ${EndIf}
          ${EndIf}
          System::Free $4
        ${Else}
          StrCpy $0 ${ERROR_OUTOFMEMORY}
        ${EndIf}
        FileClose $2
      ${EndIf}
    ${EndIf}
    System::Free $3
  ${EndIf}

  Push $0
  System::Store 'L'
FunctionEnd
!macroend ; CPIO_Write

!endif ; CPIO_INCLUDED
