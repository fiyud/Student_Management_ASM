.MODEL SMALL
.STACK 100H

.DATA
    ; Messages
    WELCOME     DB 'Welcome to Academic Login System', 13, 10, '$'
    MENU        DB '1. Login', 13, 10
                DB '2. Register', 13, 10
                DB '3. Exit', 13, 10
                DB 'Choose option: $'
    USER_TYPE   DB '1. Student', 13, 10
                DB '2. Lecturer', 13, 10
                DB 'Choice: $'
    USER_PROMPT DB 'Enter username: $'
    PASS_PROMPT DB 'Enter password: $'
    SUCCESS     DB 'Operation successful!', 13, 10, '$'
    FAIL        DB 'Operation failed!', 13, 10, '$'
    NEWLINE     DB 13, 10, '$'
    
    ; Lecturer menu
    LEC_MENU    DB '=== Lecturer Menu ===', 13, 10
                DB '1. View Student List', 13, 10
                DB '2. Add Student', 13, 10
                DB '3. Give Points', 13, 10
                DB '4. Remove Student', 13, 10
                DB '5. Logout', 13, 10
                DB 'Choose option: $'
    POINT_MSG   DB 'Enter points (0-10): $'
    STU_ID_MSG  DB 'Enter student ID: $'
    LIST_HEAD   DB 'ID    Name      Points', 13, 10, '$'
    NO_STU_MSG  DB 'No student found!', 13, 10, '$'
    
    ; File names
    STU_FILE    DB 'STUDENT.DAT', 0
    LEC_FILE    DB 'LECTURE.DAT', 0
    RECORD_FILE DB 'STUREC.DAT', 0    ; Student records file
    TEMP_FILE   DB 'TEMP.DAT', 0      ; Temporary file for operations
    
    ; Buffers
    USERNAME    DB 20 DUP(0)    ; Username buffer
    PASSWORD    DB 20 DUP(0)    ; Password buffer
    RECORD      DB 40 DUP(0)    ; Buffer for file operations
    
    ; Student record buffers (fixed length format)
    STU_ID      DB 5 DUP(0)     ; Student ID
    STU_NAME    DB 10 DUP(0)    ; Student name
    STU_POINTS  DB 0            ; Student points
    CURR_POS    DW 0            ; Current position in file
    
    FILE_HANDLE DW ?            ; File handle
    TEMP_HANDLE DW ?            ; Temporary file handle
    USER_CHOICE DB 0            ; Store user choice

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    LEA DX, WELCOME
    MOV AH, 9
    INT 21H
    
MAIN_MENU:
    LEA DX, MENU
    MOV AH, 9
    INT 21H
    
    MOV AH, 1
    INT 21H
    
    PUSH AX            
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP AX             
    
    CMP AL, '1'
    JE LOGIN_PROCESS
    CMP AL, '2'
    JE REGISTER_PROCESS
    CMP AL, '3'
    JE EXIT_PROGRAM
    JMP MAIN_MENU

LOGIN_PROCESS:
    CALL GET_USER_TYPE
    CALL GET_CREDENTIALS
    CALL VERIFY_CREDENTIALS
    JMP MAIN_MENU

REGISTER_PROCESS:
    CALL GET_USER_TYPE
    CALL GET_CREDENTIALS
    CALL STORE_CREDENTIALS
    JMP MAIN_MENU

GET_USER_TYPE:
    ; Display user type menu
    LEA DX, USER_TYPE
    MOV AH, 9
    INT 21H
    
    ; Get choice
    MOV AH, 1
    INT 21H
    
    ; Print newline after input
    PUSH AX             ; Save user's choice
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP AX              ; Restore user's choice
    
    SUB AL, '0'
    MOV USER_CHOICE, AL
    RET

GET_CREDENTIALS:
    ; Get username
    LEA DX, USER_PROMPT
    MOV AH, 9
    INT 21H
    
    LEA SI, USERNAME
    MOV CX, 10
GET_USER_LOOP:
    MOV AH, 1
    INT 21H
    CMP AL, 13          ; Check for Enter key
    JE GET_PASS_START
    MOV [SI], AL
    INC SI
    LOOP GET_USER_LOOP
    
GET_PASS_START:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    
    ; Get password
    LEA DX, PASS_PROMPT
    MOV AH, 9
    INT 21H
    
    LEA SI, PASSWORD
    MOV CX, 10
GET_PASS_LOOP:
    MOV AH, 1
    INT 21H
    CMP AL, 13          ; Check for Enter key
    JE GET_CRED_END
    MOV [SI], AL
    INC SI
    LOOP GET_PASS_LOOP
    
GET_CRED_END:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    RET

VERIFY_CREDENTIALS:
    ; Choose file based on user type
    CMP USER_CHOICE, 1
    JE OPEN_STU_LOGIN
    JMP OPEN_LEC_LOGIN

OPEN_STU_LOGIN:
    LEA DX, STU_FILE
    JMP OPEN_FOR_READ

OPEN_LEC_LOGIN:
    LEA DX, LEC_FILE

OPEN_FOR_READ:
    ; Open file for reading
    MOV AH, 3DH
    MOV AL, 0           ; Read mode
    INT 21H
    JC LOGIN_FAIL
    MOV FILE_HANDLE, AX

READ_RECORDS:
    ; Read a record
    MOV AH, 3FH
    MOV BX, FILE_HANDLE
    LEA DX, RECORD
    MOV CX, 22          ; Username(10) + Password(10) + CR(1) + LF(1)
    INT 21H
    
    CMP AX, 0           ; End of file?
    JE LOGIN_FAIL
    
    ; Compare credentials
    MOV CX, 10
    LEA SI, USERNAME
    LEA DI, RECORD
COMPARE_USER:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE READ_RECORDS    ; Try next record
    INC SI
    INC DI
    LOOP COMPARE_USER
    
    MOV CX, 10
    LEA SI, PASSWORD
COMPARE_PASS:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE READ_RECORDS    ; Try next record
    INC SI
    INC DI
    LOOP COMPARE_PASS
    
    ; Login successful
    MOV AH, 3EH         ; Close file
    MOV BX, FILE_HANDLE
    INT 21H
    
    ; Check if lecturer
    CMP USER_CHOICE, 2
    JE LECTURER_MENU
    JMP LOGIN_SUCCESS

LOGIN_FAIL:
    MOV AH, 3EH         ; Close file
    MOV BX, FILE_HANDLE
    INT 21H
    
    LEA DX, FAIL
    MOV AH, 9
    INT 21H
    RET

LOGIN_SUCCESS:
    LEA DX, SUCCESS
    MOV AH, 9
    INT 21H
    RET

LECTURER_MENU:
    ; Display lecturer menu
    LEA DX, LEC_MENU
    MOV AH, 9
    INT 21H
    
    ; Get choice
    MOV AH, 1
    INT 21H
    
    ; Print newline after input
    PUSH AX             ; Save user's choice
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP AX              ; Restore user's choice
    
    CMP AL, '1'
    JE VIEW_STUDENTS
    CMP AL, '2'
    JE ADD_STUDENT
    CMP AL, '3'
    JE GIVE_POINTS
    CMP AL, '4'
    JE REMOVE_STUDENT
    CMP AL, '5'
    JE LOGIN_SUCCESS
    JMP LECTURER_MENU

VIEW_STUDENTS:
    ; Open student records file
    LEA DX, RECORD_FILE
    MOV AH, 3DH         ; Open file
    MOV AL, 0           ; Read mode
    INT 21H
    JC NO_STUDENTS      ; If file doesn't exist
    
    MOV FILE_HANDLE, AX
    
    ; Display header
    LEA DX, LIST_HEAD
    MOV AH, 9
    INT 21H
    
VIEW_LOOP:
    ; Read student record
    MOV AH, 3FH         ; Read file
    MOV BX, FILE_HANDLE
    LEA DX, RECORD      ; Use RECORD buffer
    MOV CX, 18          ; Record size (ID + Name + Points + CRLF)
    INT 21H
    
    CMP AX, 0           ; Check if end of file
    JE CLOSE_VIEW
    
    ; Display ID (first 5 characters)
    MOV CX, 5           ; ID length
    LEA SI, RECORD
SHOW_ID:
    MOV DL, [SI]        ; Get character
    MOV AH, 2           ; Display character
    INT 21H
    INC SI
    LOOP SHOW_ID
    
    ; Display spaces
    MOV DL, 20h         ; Space
    MOV AH, 2
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    
    ; Display Name (next 10 characters)
    MOV CX, 10          ; Name length
SHOW_NAME:
    MOV DL, [SI]        ; Get character
    MOV AH, 2           ; Display character
    INT 21H
    INC SI
    LOOP SHOW_NAME
    
    ; Display spaces
    MOV DL, 20h         ; Space
    MOV AH, 2
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    
    ; Display Points (1 byte)
    MOV DL, [SI]        ; Get points value
    ADD DL, 30h         ; Convert to ASCII
    MOV AH, 2           ; Display character
    INT 21H
    
    ; Display newline
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    
    JMP VIEW_LOOP
    
CLOSE_VIEW:
    MOV AH, 3EH         ; Close file
    MOV BX, FILE_HANDLE
    INT 21H
    JMP VIEW_DONE
    
NO_STUDENTS:
    LEA DX, NO_STU_MSG
    MOV AH, 9
    INT 21H
    
VIEW_DONE:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    JMP LECTURER_MENU

ADD_STUDENT:
    ; Get student ID
    LEA DX, STU_ID_MSG
    MOV AH, 9
    INT 21H
    
    ; Read student ID
    LEA SI, STU_ID
    MOV CX, 5           ; Read 5 characters for ID
ADD_ID_LOOP:
    MOV AH, 1
    INT 21H
    CMP AL, 13          ; Check for Enter key
    JE ADD_ID_DONE
    MOV [SI], AL
    INC SI
    LOOP ADD_ID_LOOP
ADD_ID_DONE:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    
    ; Get student name
    LEA DX, USER_PROMPT
    MOV AH, 9
    INT 21H
    
    ; Read student name
    LEA SI, STU_NAME
    MOV CX, 10          ; Read 10 characters for name
ADD_NAME_LOOP:
    MOV AH, 1
    INT 21H
    CMP AL, 13          ; Check for Enter key
    JE ADD_NAME_DONE
    MOV [SI], AL
    INC SI
    LOOP ADD_NAME_LOOP
ADD_NAME_DONE:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    
    ; Initialize points to 0
    MOV STU_POINTS, 0
    
    ; Open/Create student records file
    LEA DX, RECORD_FILE
    MOV AH, 3DH         ; Try to open existing file first
    MOV AL, 2           ; Read/Write mode
    INT 21H
    JNC APPEND_STUDENT  ; If file opened successfully
    
    ; If file doesn't exist, create it
    LEA DX, RECORD_FILE
    MOV AH, 3CH         ; Create file
    MOV CX, 0           ; Normal attributes
    INT 21H
    JC ADD_FAIL         ; If create fails

APPEND_STUDENT:
    MOV FILE_HANDLE, AX
    
    ; Seek to end of file
    MOV AH, 42H         ; SEEK
    MOV AL, 2           ; From end of file
    MOV BX, FILE_HANDLE
    XOR CX, CX
    XOR DX, DX
    INT 21H
    
    ; Write student ID
    MOV AH, 40H
    MOV BX, FILE_HANDLE
    LEA DX, STU_ID
    MOV CX, 5           ; ID length
    INT 21H
    
    ; Write student name
    MOV AH, 40H
    MOV BX, FILE_HANDLE
    LEA DX, STU_NAME
    MOV CX, 10          ; Name length
    INT 21H
    
    ; Write points
    MOV AH, 40H
    MOV BX, FILE_HANDLE
    LEA DX, STU_POINTS
    MOV CX, 1           ; Points length
    INT 21H
    
    ; Write newline
    MOV AH, 40H
    MOV BX, FILE_HANDLE
    LEA DX, NEWLINE
    MOV CX, 2           ; CR+LF
    INT 21H
    
    ; Close file
    MOV AH, 3EH
    MOV BX, FILE_HANDLE
    INT 21H
    
    ; Clear student buffers
    ; Clear student ID buffer
    LEA SI, STU_ID
    MOV BX, 5           
CLEAR_ID:
    MOV BYTE PTR [SI], 0
    INC SI
    DEC BX
    JNZ CLEAR_ID
    
    ; Clear student name buffer
    LEA SI, STU_NAME
    MOV BX, 10         
CLEAR_NAME:
    MOV BYTE PTR [SI], 0
    INC SI
    DEC BX
    JNZ CLEAR_NAME
    
    LEA DX, SUCCESS
    MOV AH, 9
    INT 21H
    JMP LECTURER_MENU
    
ADD_FAIL:
    LEA DX, FAIL
    MOV AH, 9
    INT 21H
    JMP LECTURER_MENU

GIVE_POINTS:
    ; Clear student ID buffer first
    LEA SI, STU_ID
    MOV CX, 5
CLEAR_ID_BUFFER:
    MOV BYTE PTR [SI], 0
    INC SI
    LOOP CLEAR_ID_BUFFER

    ; Open student records file
    LEA DX, STU_FILE   
    MOV AH, 3DH         
    MOV AL, 2          
    INT 21H
    JC NO_RECORDS       
    
    MOV FILE_HANDLE, AX

ENTER_ID:
    ; Get student ID
    LEA DX, STU_ID_MSG
    MOV AH, 9
    INT 21H
    
    ; Read student ID
    MOV CX, 5          
    LEA SI, STU_ID
GET_ID:
    MOV AH, 1
    INT 21H
    
    CMP AL, 13         
    JE CHECK_EARLY_EXIT
    
    MOV [SI], AL
    INC SI
    LOOP GET_ID
    
    ; Add newline after ID input
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H

    ; Save beginning position
    MOV AH, 42H         
    MOV AL, 1           
    MOV BX, FILE_HANDLE
    XOR CX, CX
    XOR DX, DX
    INT 21H
    
    MOV CURR_POS, 0     
    
SEARCH_LOOP:
    ; Read one record
    MOV AH, 3FH         
    MOV BX, FILE_HANDLE
    LEA DX, RECORD      
    MOV CX, 18          
    INT 21H
    
    CMP AX, 0           
    JE ID_NOT_FOUND
    
    ; Compare ID
    MOV CX, 5           
    LEA SI, STU_ID
    LEA DI, RECORD
    PUSH CX             
    
COMPARE_ID:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE ID_NEXT         
    INC SI
    INC DI
    LOOP COMPARE_ID
    
    POP CX              
    JMP GET_POINTS      
    
ID_NEXT:
    POP CX              
    ADD CURR_POS, 18    
    JMP SEARCH_LOOP
    
GET_POINTS:
    ; Ask for grade
    LEA DX, POINT_MSG
    MOV AH, 9
    INT 21H
    
    ; Get grade (0-10)
    MOV AH, 1
    INT 21H
    
    SUB AL, '0'         
    CMP AL, 0           
    JL INVALID_GRADE
    CMP AL, 9
    JG CHECK_TEN
    
    ; Store grade (0-9)
    MOV BYTE PTR [RECORD + 15], AL
    JMP UPDATE_RECORD
    
CHECK_TEN:
    CMP AL, 1           
    JNE INVALID_GRADE
    
    ; Get second digit
    MOV AH, 1
    INT 21H
    CMP AL, '0'         
    JNE INVALID_GRADE
    
    MOV AL, 10          
    MOV BYTE PTR [RECORD + 15], AL
    
UPDATE_RECORD:
    ; Move back to start of record
    MOV AH, 42H
    MOV AL, 0           
    MOV BX, FILE_HANDLE
    XOR CX, CX
    MOV DX, CURR_POS    
    INT 21H
    
    ; Write updated record
    MOV AH, 40H
    MOV BX, FILE_HANDLE
    LEA DX, RECORD
    MOV CX, 18          
    INT 21H
    
    ; Show success
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    LEA DX, SUCCESS
    MOV AH, 9
    INT 21H
    JMP CLOSE_POINTS
    
INVALID_GRADE:
    LEA DX, FAIL
    MOV AH, 9
    INT 21H
    JMP CLOSE_POINTS
    
CHECK_EARLY_EXIT:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    JMP CLOSE_POINTS
    
ID_NOT_FOUND:
    LEA DX, NO_STU_MSG
    MOV AH, 9
    INT 21H
    JMP ENTER_ID
    
NO_RECORDS:
    LEA DX, NO_STU_MSG
    MOV AH, 9
    INT 21H
    
CLOSE_POINTS:
    MOV AH, 3EH         ; Close file
    MOV BX, FILE_HANDLE
    INT 21H
    JMP LECTURER_MENU

REMOVE_STUDENT:
    ; Clear student ID buffer first
    LEA SI, STU_ID
    MOV CX, 5
    CALL CLEAR_BUFFER

    ; First check if original file exists
    LEA DX, RECORD_FILE
    MOV AH, 3DH        
    MOV AL, 0          
    INT 21H
    JC NO_RECORDS      
    
    ; Close the file and reopen in read/write mode
    MOV BX, AX
    MOV AH, 3EH
    INT 21H
    
    ; Open file again in read/write mode
    LEA DX, RECORD_FILE
    MOV AH, 3DH         
    MOV AL, 2           
    INT 21H    
    MOV FILE_HANDLE, AX

    ; Get student ID to remove
    LEA DX, STU_ID_MSG
    MOV AH, 9
    INT 21H
    
    ; Read student ID
    MOV CX, 5           ; Read 5 characters for ID
    LEA SI, STU_ID
REM_GET_ID:
    MOV AH, 1
    INT 21H
    
    CMP AL, 13          ; Check for Enter key
    JE REM_EARLY_EXIT
    
    MOV [SI], AL
    INC SI
    LOOP REM_GET_ID
    
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H

    ; Create temporary file
    LEA DX, TEMP_FILE
    MOV AH, 3CH        
    XOR CX, CX         
    INT 21H
    JC REMOVE_FAIL
    
    MOV TEMP_HANDLE, AX
    
    ; Reset file pointer to start
    MOV AH, 42H
    MOV AL, 0           
    MOV BX, FILE_HANDLE
    XOR CX, CX
    XOR DX, DX
    INT 21H

REMOVE_LOOP:
    ; Read from original file
    MOV AH, 3FH         
    MOV BX, FILE_HANDLE
    LEA DX, RECORD
    MOV CX, 18          
    INT 21H
    
    CMP AX, 0           
    JE FINISH_REMOVE
    
    PUSH AX             
    
    ; Compare ID with current record
    MOV CX, 5          
    LEA SI, STU_ID
    LEA DI, RECORD
    PUSH CX             
    
COMPARE_REM_ID:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE COPY_RECORD     
    INC SI
    INC DI
    LOOP COMPARE_REM_ID
    
    ; If we get here, IDs match - skip this record
    POP CX             
    POP AX             
    MOV BYTE PTR [RECORD], 0    
    JMP REMOVE_LOOP
    
COPY_RECORD:
    POP CX             
    POP CX             
    
    ; Check if record is marked as deleted
    CMP BYTE PTR [RECORD], 0
    JE REMOVE_LOOP      ; Skip if deleted
    
    ; Write record to temp file
    MOV AH, 40H
    MOV BX, TEMP_HANDLE
    LEA DX, RECORD
    MOV CX, 18         
    INT 21H
    
    JMP REMOVE_LOOP
    
FINISH_REMOVE:
    ; Close both files
    MOV AH, 3EH
    MOV BX, FILE_HANDLE
    INT 21H
    
    MOV AH, 3EH
    MOV BX, TEMP_HANDLE
    INT 21H
    
    ; Delete original file
    LEA DX, RECORD_FILE
    MOV AH, 41H         ; Delete file
    INT 21H
    
    ; Rename temp file to original name
    LEA DX, TEMP_FILE   
    LEA DI, RECORD_FILE
    MOV AH, 56H         
    INT 21H
    
    LEA DX, SUCCESS
    MOV AH, 9
    INT 21H
    JMP LECTURER_MENU
    
REMOVE_FAIL:
    LEA DX, FAIL
    MOV AH, 9
    INT 21H
    JMP LECTURER_MENU
    
REM_EARLY_EXIT:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    
    ; Close files if open
    MOV AH, 3EH
    MOV BX, FILE_HANDLE
    INT 21H
    
    CMP TEMP_HANDLE, 0
    JE REM_EXIT_DONE
    MOV AH, 3EH
    MOV BX, TEMP_HANDLE
    INT 21H
    
REM_EXIT_DONE:
    JMP LECTURER_MENU

CLEAR_BUFFER:
    ; SI = buffer address, CX = length
    PUSH CX
CLEAR_LOOP:
    MOV BYTE PTR [SI], 0
    INC SI
    LOOP CLEAR_LOOP
    POP CX
    RET

EXIT_PROGRAM:
    MOV AH, 4CH
    INT 21H

STORE_CREDENTIALS:
    ; Choose file based on user type
    CMP USER_CHOICE, 1
    JE CREATE_STU_FILE
    JMP CREATE_LEC_FILE

CREATE_STU_FILE:
    LEA DX, STU_FILE
    JMP CREATE_USER_FILE

CREATE_LEC_FILE:
    LEA DX, LEC_FILE
    
CREATE_USER_FILE:
    ; Try to create new file
    MOV AH, 3CH         
    MOV CX, 0           
    INT 21H
    JNC FILE_CREATED    
    
    ; If file exists, open it for append
    MOV AH, 3DH         ; Open file function
    MOV AL, 2           
    INT 21H
    JNC FILE_OPENED
    JMP STORE_FAIL      
    
FILE_CREATED:
    MOV FILE_HANDLE, AX
    JMP WRITE_CREDS

FILE_OPENED:
    MOV FILE_HANDLE, AX
    
    ; Seek to end of file
    MOV AH, 42H         
    MOV AL, 2           
    MOV BX, FILE_HANDLE
    XOR CX, CX          
    XOR DX, DX          
    INT 21H

WRITE_CREDS:
    ; Write username
    MOV AH, 40H         
    MOV BX, FILE_HANDLE
    LEA DX, USERNAME
    MOV CX, 10          
    INT 21H
    
    ; Write password
    MOV AH, 40H
    MOV BX, FILE_HANDLE
    LEA DX, PASSWORD
    MOV CX, 10          
    INT 21H
    
    ; Write newline
    MOV AH, 40H
    MOV BX, FILE_HANDLE
    LEA DX, NEWLINE
    MOV CX, 2           
    INT 21H
    
    ; Close file
    MOV AH, 3EH
    MOV BX, FILE_HANDLE
    INT 21H
    
    LEA DX, SUCCESS
    MOV AH, 9
    INT 21H
    RET
    
STORE_FAIL:
    LEA DX, FAIL
    MOV AH, 9
    INT 21H
    RET

MAIN ENDP
END MAIN