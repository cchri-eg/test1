     FAS15214D  CF   E             WORKSTN SFILE(LOADALL:RRN) INFDS(DSPFBK)
     FTROCU00   UF A E           K DISK
     FFINDBRANCHIF   E           K DISK
      *
     DDSPFBK           DS
     DSF_RRN                 376    377I 0
     DMIN_RRN                378    379I 0
     DNUM_RCDS               380    381I 0
      *
     DKEY              S                   LIKE(CUKNR)
     DTEMPCUKNR        S             10A
     DTEMPBRANCH       S                   LIKE(CUFILI)
     DTEMPNAME         S                   LIKE(CUNAMN)
     DTEMPTEL          S                   LIKE(CUTEL1)
     DTEMPADD          S                   LIKE(CUADR1)
     DTEMPPNR          S                   LIKE(CUPNR)
     DTEMPADR          S                   LIKE(CUPADR)
     DRRN              S              4S 0
     DSFLRRN           S              4S 0
      *
     DDS1             SDS
     DUSER                   254    263
      *
        /FREE
            RCDNBR = 1;
            EXSR $MAIN;
            DOW *IN03 = *OFF;
                WRITE FOOTER;
                EXFMT LOADCTRL;
                IF *IN51 = *ON;
                   SFLRRN = MIN_RRN;
                ENDIF;
                CTRLERROR = '';
                SELECT;
                    WHEN %TRIM(CUKNR1)<> '' AND CUFILI1 <> 0 ;
                        CUKNR = %TRIM(CUKNR1);
                        CUFILI = CUFILI1;
                        IF MAINOPT = 0;
                            CHAIN (CUKNR:CUFILI) TROCU00;
                            EXSR $FILTERRECORD;
                            ITER;
                        ELSEIF MAINOPT = 1;
                            CLEAR CREATEDSPF;
                            CUKNR = %TRIM(CUKNR1);
                            CUFILI = CUFILI1;
                            EXSR $CREATERECORD;
                        ELSEIF MAINOPT = 2;
                            EXSR $UPDATERECORD;
                        ELSEIF MAINOPT = 3;
                            EXSR $COPYRECORD;
                        ELSEIF MAINOPT = 4;
                            EXSR $DELETERECORD;
                        ELSEIF MAINOPT = 5;
                            EXSR $DISPLAYRECORD;
                        ENDIF;
                    WHEN %TRIM(CUKNR1) <> '' AND CUFILI1 = 0;
                       IF MAINOPT = 1;
                          CLEAR CREATEDSPF;
                          CUKNR = %TRIM(CUKNR1);
                          EXSR $CREATERECORD;
                       ELSE;
                        KEY = %TRIM(CUKNR1);
                        CHAIN KEY TROCU00;
                        EXSR $FILTERRECORD;
                      ENDIF;
                        ITER;
                    WHEN CUFILI1 <> 0 AND CUKNR1 = '';
                       IF MAINOPT = 1;
                         CLEAR CREATEDSPF;
                         CUFILI = CUFILI1;
                         EXSR $CREATERECORD;
                      ELSE;
                        CHAIN CUFILI1 FINDBRANCH;
                        EXSR $CLEARSFL;
                        IF NOT %FOUND;
                            CTRLERROR = 'RECORD NOT FOUND';
                            ITER;
                        ENDIF;
                        DOW NOT %EOF(FINDBRANCH);
                            RRN= RRN+1;
                            WRITE LOADALL;
                            READE CUFILI1 FINDBRANCH;
                        ENDDO;
                        *IN51 = *ON;
                        RCDNBR = 1;
                        ENDIF;
                        ITER;
                    WHEN MAINOPT = 1;
                        CLEAR CREATEDSPF;
                        EXSR $CREATERECORD;
                    WHEN *IN06 = *ON;
                        EXSR $MAIN;
                        CTRLERROR = '';
                        *IN06 = *OFF;
                        ITER;
                    OTHER;
                ENDSL;
                READC LOADALL;
                DOW NOT %EOF;
                SELECT;
                    WHEN OPT = 2;
                            EXSR $UPDATERECORD;
                    WHEN OPT = 3;
                            EXSR $COPYRECORD;
                    WHEN OPT = 4;
                            EXSR  $DELETERECORD;
                    WHEN OPT = 5;
                            EXSR $DISPLAYRECORD;
                    OTHER;
                ENDSL;
                READC LOADALL;
                ENDDO;
            EXSR $MAIN;
            RCDNBR= SFLRRN;
            ENDDO;
            *INLR = *ON;
        /END-FREE
      *
        /FREE
            BEGSR $MAIN;
                EXSR $CLEARSFL;
                EXSR $LOADSFL;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $CLEARSFL;
                *IN50 = *OFF;
                *IN51 = *OFF;
                WRITE LOADCTRL;
                RRN = 0;
                *IN50 = *ON;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $LOADSFL;
                SETLL *LOVAL TROCU00;
                READ TROCU00;
                DOW NOT %EOF(TROCU00);
                    RRN = RRN+1;
                    WRITE LOADALL;
                    IF CUKNR = TEMPCUKNR AND CUFILI = TEMPBRANCH;
                        SFLRRN = RRN;
                    ENDIF;
                    READ TROCU00;
                ENDDO;
                IF RRN>0;
                    *IN51 = *ON;
                ENDIF;
                IF TEMPCUKNR = '' AND TEMPBRANCH = 0;
                    RCDNBR = 1;
                ENDIF;
                TEMPCUKNR = '';
                TEMPBRANCH = 0;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $CREATERECORD;
                DOW *IN12 = *OFF;
                    EXFMT CREATEDSPF;
                    EXSR $INSERTRECORD;
                ENDDO;
                *IN12 = *OFF;
                CLEAR CREATEDSPF;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $INSERTRECORD;
                TEMPNAME = CUNAMN;
                TEMPTEL = CUTEL1;
                TEMPADD = CUADR1;
                TEMPPNR = CUPNR;
                TEMPADR = CUPADR;
                IF CUFILI = 0 OR
                CUNAMN = *BLANK OR
                CUADR1 = *BLANK OR
                CUPADR = *BLANK OR
                CUTEL1 = *BLANK OR
                CUKNR = *BLANK;
                    ERRORMSG = 'ERROR: ALL REQUIRED FIELDS MUST BE FILLED';
                ELSE;
                    CHAIN (CUKNR:CUFILI) TROCU00;
                    IF %FOUND;
                        ERRORMSG = 'CUSTOMER NUMBER IS ALREADY PRESENT';
                        CUNAMN = TEMPNAME;
                        CUTEL1 = TEMPTEL;
                        CUADR1 = TEMPADD;
                        CUPNR = TEMPPNR;
                        CUPADR = TEMPADR;
                        LEAVESR;
                    ELSE;
                        CUDAT = %DEC(%CHAR(%DATE():*ISO0):8:0);
                    CUTID = %DEC(%SUBST(%CHAR(%TIMESTAMP():*ISO0):9:6):6:0);
                    CUDATU = %DEC(%CHAR(%DATE():*ISO0):8:0);
                    CUTIDU = %DEC(%SUBST(%CHAR(%TIMESTAMP():*ISO0):9:6):6:0);
                    CUKOD = 1;
                    CUUSR = USER;
                    CUUSRU = USER;
                    WRITE TROCUREC;
                    TEMPCUKNR = CUKNR;
                    TEMPBRANCH = CUFILI;
                    CLEAR CREATEDSPF;
                    ERRORMSG = 'RECORD ADDED SUCCESFULLY';
                    ENDIF;
                ENDIF;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $UPDATERECORD;
                CHAIN (CUKNR:CUFILI) TROCU00;
                IF NOT %FOUND;
                   CTRLERROR = 'RECORD NOT FOUND';
                   LEAVESR;
                ENDIF;
                IF CUWSID <> '';
                    CTRLERROR = 'RECORD IS CURRENTLY LOCKED ';
                LEAVESR;
                ENDIF;
                CUWSID = USER;
                UPDATE TROCUREC;
                DOW *IN12 = *OFF;
                    EXFMT UPDATEDSPF;
                TEMPNAME = CUNAMN;
                TEMPBRANCH = CUFILI;
                TEMPTEL = CUTEL1;
                TEMPADD = CUADR1;
                TEMPPNR = CUPNR;
                TEMPADR = CUPADR;
                CHAIN (CUKNR:CUFILI) TROCU00;
                IF TEMPNAME <> CUNAMN OR
                    TEMPTEL <> CUTEL1 OR
                    TEMPADD <> CUADR1 OR
                    TEMPPNR <> CUPNR OR
                    TEMPADR <> CUPADR ;
                    IF TEMPNAME = *BLANK OR
                        TEMPADD = *BLANK OR
                        TEMPTEL = *BLANK OR
                        TEMPADR = *BLANK OR
                        TEMPPNR = *BLANK ;
                        ERRORMSG = 'FIELDS CANNOT BE BLANK';
                        ITER;
                    ENDIF;
                    CUNAMN = TEMPNAME;
                    CUFILI = TEMPBRANCH;
                    CUTEL1 = TEMPTEL;
                    CUADR1 = TEMPADD;
                    CUPNR = TEMPPNR;
                    CUPADR = TEMPADR;
                    CUUSRU = USER;
                    CUDATU = %DEC(%CHAR(%DATE():*ISO0):8:0);
                    CUTIDU = %DEC(%SUBST(%CHAR(%TIMESTAMP():*ISO0):9:6):6:0);
                    UPDATE TROCUREC;
                    CTRLERROR = 'RECORD UPDATED';
                    *IN12 = *ON;
                ELSE;
                    *IN12 = *ON;
                ENDIF;
                ENDDO;
                *IN12 = *OFF;
                TEMPCUKNR = CUKNR;
                TEMPBRANCH = CUFILI;
                CHAIN (CUKNR:CUFILI) TROCU00;
                CUWSID = '';
                UPDATE TROCUREC;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $COPYRECORD;
                CHAIN (CUKNR:CUFILI) TROCU00;
                IF NOT %FOUND;
                   CTRLERROR = 'RECORD NOT FOUND';
                   LEAVESR;
                ENDIF;
                DOW *IN12 = *OFF;
                    CHAIN (CUKNR:CUFILI) TROCU00;
                    TEMPCUKNR = CUKNR;
                    TEMPBRANCH = CUFILI;
                    CUKNR = *BLANK;
                    CUFILI = 0;
                    EXFMT COPYDSPF;
                        TEMPNAME = CUNAMN;
                        TEMPTEL = CUTEL1;
                        TEMPADD = CUADR1;
                        TEMPPNR = CUPNR;
                        TEMPADR = CUPADR;
                    CHAIN (CUKNR:CUFILI) TROCU00;
                    IF %FOUND ;
                        ERRORMSG = 'CUSTOMER NUMBER AND BRANCH ALREADY EXIST';
                        CUKNR = '';
                        CUFILI = 0;
                                CUNAMN = TEMPNAME;
                                CUTEL1 = TEMPTEL;
                                CUADR1 = TEMPADD;
                                CUPNR = TEMPPNR;
                                CUPADR = TEMPADR;
                    ELSEIF CUKNR='' OR CUFILI = 0;
                        ERRORMSG = 'FIELDS CANNOT BE BLANK';
                    ELSE;
                        TEMPCUKNR = CUKNR;
                        TEMPBRANCH = CUFILI;
                        CUDAT = %DEC(%CHAR(%DATE():*ISO0):8:0);
                    CUTID = %DEC(%SUBST(%CHAR(%TIMESTAMP():*ISO0):9:6):6:0);
                    CUDATU = %DEC(%CHAR(%DATE():*ISO0):8:0);
                    CUTIDU = %DEC(%SUBST(%CHAR(%TIMESTAMP():*ISO0):9:6):6:0);
                    CUKOD = 1;
                    CUUSR = USER;
                    CUUSRU = USER;
                        WRITE TROCUREC;
                        CLEAR COPYDSPF;
                        CTRLERROR = 'RECORD IS COPIED';
                        LEAVESR;
                    ENDIF;
                ENDDO;
                *IN12 = *OFF;
                CLEAR CREATEDSPF;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $DELETERECORD;
                CHAIN (CUKNR:CUFILI) TROCU00;
                IF NOT %FOUND;
                   CTRLERROR = 'RECORD NOT FOUND';
                   LEAVESR;
                ENDIF;
                IF CUWSID <> '';
                    CTRLERROR = 'RECORD IS CURRENTLY LOCKED ';
                    LEAVESR;
                ENDIF;
                IF %FOUND;
                    CUWSID = USER;
                    UPDATE TROCUREC;
                    DOW *IN12 = *OFF;
                        EXFMT CONFIRMDLT;
                        IF CONFIRM = 'Y';
                           CHAIN (CUKNR:CUFILI) TROCU00;
                           DELETE TROCUREC;
                           CTRLERROR = 'RECORD IS DELETED';
                           LEAVESR;
                        ELSEIF CONFIRM = 'N';
                           *IN12 = *ON;
                        ELSE;
                           DLTERRMSG = 'CHOOSE Y OR N';
                        ENDIF;
                    ENDDO;
                        *IN12 = *OFF;
                        DLTERRMSG = '';
                        CHAIN (CUKNR:CUFILI) TROCU00;
                        TEMPCUKNR = CUKNR;
                        TEMPBRANCH = CUFILI;
                        CUWSID = '';
                        UPDATE TROCUREC;
                ELSE;
                    CTRLERROR = 'RECORD NOT FOUND';
                ENDIF;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $FILTERRECORD;
                EXSR $CLEARSFL;
                IF %FOUND AND CUFILI1 = 0;
                    DOW NOT %EOF(TROCU00);
                        RRN = RRN+1;
                        WRITE LOADALL;
                        READE KEY TROCU00;
                    ENDDO;
                ELSEIF %FOUND AND CUFILI1 <> 0;
                    RRN = RRN+1;
                    WRITE LOADALL;
                ELSE;
                    CTRLERROR = 'RECORD NOT FOUND';
                ENDIF;
                IF RRN>0;
                    *IN51 = *ON;
                    RCDNBR = 1;
                ENDIF;
            ENDSR;
        /END-FREE
      *
        /FREE
            BEGSR $DISPLAYRECORD;
                CHAIN (CUKNR:CUFILI) TROCU00;
                IF %FOUND;
                    EXFMT DSPDETAIL;
                ELSE;
                   CTRLERROR = 'RECORD NOT FOUND';
                ENDIF;
                TEMPCUKNR = CUKNR;
                TEMPBRANCH = CUFILI;
            ENDSR;
        /END-FREE
