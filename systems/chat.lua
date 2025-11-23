-- BYTECODE -- commands.lua:7-13
0001    GGET     2   0      ; "assert"
0002    TGETS    4   1   1  ; "name"
0003    KSTR     5   2      ; "Command must have a name"
0004    CALL     2   1   3
0005    GGET     2   0      ; "assert"
0006    TGETS    4   1   3  ; "execute"
0007    KSTR     5   4      ; "Command must have an execute function"
0008    CALL     2   1   3
0009    GGET     2   0      ; "assert"
0010    MOV      6   0
0011    TGETS    4   0   5  ; "exists"
0012    TGETS    7   1   1  ; "name"
0013    CALL     4   2   3
0014    NOT      4   4
0015    KSTR     5   6      ; "Command already exists: "
0016    GGET     6   7      ; "tostring"
0017    TGETS    8   1   1  ; "name"
0018    CALL     6   2   2
0019    CAT      5   5   6
0020    CALL     2   1   3
0021    TGETS    2   1   1  ; "name"
0022    TSETV    1   0   2
0023    TGETS    2   1   1  ; "name"
0024    RET1     2   2

-- BYTECODE -- commands.lua:16-18
0001    TGETV    2   0   1
0002    RET1     2   2

-- BYTECODE -- commands.lua:21-27
0001    MOV      5   0
0002    TGETS    3   0   0  ; "get"
0003    MOV      6   1
0004    CALL     3   2   3
0005    ISF          3
0006    JMP      4 => 0010
0007    TGETS    4   3   1  ; "execute"
0008    MOV      6   2
0009    CALLT    4   2
0010 => KPRI     4   1
0011    KSTR     5   2      ; "Unknown command: "
0012    GGET     6   3      ; "tostring"
0013    MOV      8   1
0014    CALL     6   2   2
0015    CAT      5   5   6
0016    RET      4   3

-- BYTECODE -- commands.lua:30-32
0001    TGETV    2   0   1
0002    ISNEP    2   0
0003    JMP      2 => 0006
0004    KPRI     2   1
0005    JMP      3 => 0007
0006 => KPRI     2   2
0007 => RET1     2   2

-- BYTECODE -- commands.lua:0-35
0001    TNEW     0   0
0002    FNEW     1   1      ; commands.lua:7
0003    TSETS    1   0   0  ; "register"
0004    FNEW     1   3      ; commands.lua:16
0005    TSETS    1   0   2  ; "get"
0006    FNEW     1   5      ; commands.lua:21
0007    TSETS    1   0   4  ; "execute"
0008    FNEW     1   7      ; commands.lua:30
0009    TSETS    1   0   6  ; "exists"
0010    UCLO     0 => 0011
0011 => RET1     0   2

