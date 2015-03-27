program apm_tester;

uses newdelay, crt;

{

This is freeware. Use at your own risk.

Email the author at: chart@hyperlink.net.au
Author's home page : http://home.hyperlink.net.au/~chart

}


const
  prog_version		: string[5] = '0.01á';


var
  apm,
  failed		: boolean;

  version,
  sig,
  flags,
  state,
  batttime		: word;

  i			: integer;

  ch			: char;

  acstatus,
  battstatus,
  battflag,
  battlife,
  err			: byte;



procedure showcode;
begin
  write('Failed : ');
  case err of
    1 : write('PM Functionality disabled');
    2 : write('RM interface already established');
    3 : write('Interface not connected');
    5 : write('16-bit PM mode interface alewady established');
    9 : write('Unrecognised device ID');
    $60 : write('Unable to enter requested state');
    else write('error code ',err);
  end;
end;

procedure busy;
begin
  write('CPU Busy ');
  asm
    mov failed,true

    mov ax,5306h
    int 15h
    jc @exit
    mov failed,false

  @exit:
    mov err,ah
  end;
  if failed then showcode else writeln('OK');
end;


procedure idle;
begin
  write('CPU Idle ');

  asm
    mov failed,true

    mov ax,5305h
    int 15h
    jc @exit
    mov failed,false

  @exit:
    mov err,ah
  end;
  if failed then showcode else writeln('OK');
end;


procedure enable;
begin
  write('Enable APM ');

  asm
    mov failed,true

    mov ax,5308h
    mov bx,1
    mov cx,1
    int 15h
    jc @exit

    mov failed,false

  @exit:
    mov err,ah
  end;
  if failed then showcode else writeln('OK');
end;

procedure disable;
begin
  write('Disble APM ');

  asm
    mov failed,true

    mov ax,5308h
    mov bx,1
    mov cx,0
    int 15h
    jc @exit

    mov failed,false

  @exit:
    mov err,ah
  end;
  if failed then showcode else writeln('OK');
end;

procedure setstate(sta:word);
begin
  write('Set Power State ');
  case
  sta of
    0 : write('Enabled ');
    1 : write('Standby ');
    2 : write('Suspend ');
    3 : write('Off ');
  end;

  asm
    mov failed,true

    mov ax,5307h
    mov bx,1
    mov cx,sta

    int 15h
    jc @exit

    mov failed,false



  @exit:
    mov err,ah
  end;
  if failed then showcode else writeln('OK');
end;

procedure restore;
begin
  write('Restore Defaults ');

  asm
    mov failed,true

    mov ax,5309h
    mov bx,1
    int 15h
    jc @exit

    mov failed,false

  @exit:
    mov err,ah
  end;
  if failed then showcode else writeln('OK');
end;



procedure showstatus;
begin
  asm
    mov failed,true

    mov ax,530ah
    mov bx,1
    int 15h
    jc @exit

    mov failed,false
    mov acstatus,bh
    mov battstatus,bl
    mov battflag,ch
    mov battlife,cl
    mov batttime,dx


  @exit:
    mov err,ah
  end;

  if failed then showcode else
  begin
    write('AC : ');
    case acstatus of
      00 : write('Off-Line  ');
      01 : write('On-Line   ');
      02 : write('On Backup ');
      $ff : write('Unknown   ');
    end;
    write('Batt Status : ');
    case battstatus of
      00 : write('High       ');
      01 : write('Low        ');
      02 : write('Charging   ');
      $ff : write('Unknown    ');
    end;
    write('Batt Flag : ');

    if battflag=$ff then writeln('Unknown')
    else
    begin
      if battflag and 1=1 then writeln('High              ');
      if battflag and 2=2 then writeln('Low               ');
      if battflag and 4=4 then writeln('Critical          ');
      if battflag and 8=8 then writeln('Charging          ');
      if battflag and 16=16 then writeln('Batt not present  ');
      if battflag and 128=128 then writeln('No system battery ');
    end;

    write('Batt Life : ');
    if battlife=$ff then write('Unknown    ') else write(battlife:3,'%       ');

    write('Power State : ');
    asm
      mov failed,true

      mov ax,530ch
      mov bx,1
      int 15h
      jc @exit

      mov failed,false
      mov state,cx

    @exit:
      mov err,ah
    end;

    if failed then showcode else
    begin
      case state of
        0 : write('APM Enabled  ');
        1 : write('Standby      ');
        2 : write('Suspend      ');
        3 : write('Off          ');
        else write('Unknown (',state,')');
      end;
    end;
  end;
end;



procedure dispbasics;
begin
  apm:=false;
  asm
    mov failed,true

    mov ax,5300h
    mov bx,0
    int 015h
    jc @exit

    mov failed,false
    mov version,ax
    mov sig,bx
    mov flags,cx


  @exit:
  end;

  if not failed then
  begin
    apm:=true;
    write('APM Version ',hi(version),'.',lo(version),' detected; ');
    writeln('Signature : ',chr(hi(sig)),chr(lo(sig)));


    write('16 bit PM interface ');
    if flags and 1=1 then write('supported') else write('not supported');
    write(', 32 bit PM interface ');
    if flags and 2=2 then writeln('supported') else writeln('not supported');

    write('CPU idle call ');
    if flags and 4=4 then writeln('supported') else writeln('not supported');

    write('Power management ');
    if flags and 8=8 then write('disabled, ') else write('not disabled, ');
    if flags and 16=16 then writeln('disengaged') else writeln('not disengaged');
  end;
end;








begin
  clrscr;
  gotoxy(1,1);

  dispbasics;

  writeln;
  if apm then
  begin
    write('Connect RM Interface ');
    asm
      mov failed,true

      mov ax,5301h
      mov bx,0
      int 15h


      jc @exit
      mov failed,false

    @exit:
      mov err,ah
    end;

    if failed then showcode else writeln('OK');

    write('Set APM Driver version 1.1 ');
    asm
      mov failed,true

      mov ax,530eh
      mov bx,0
      mov cx,0101h
      int 15h

      jc @exit
      mov failed,false

    @exit:
      mov err,ah
    end;

    if failed then showcode else writeln('OK');



    writeln;
    writeln('Select:');
    writeln;
    writeln('1.  Call CPU Idle');
    writeln('2.  Call CPU Busy');
    writeln('3.  Disable APM');
    writeln('4.  Enable APM');
    writeln('5.  Call Set power state Enabled');
    writeln('6.  Call Set power state Standby');
    writeln('7.  Call Set power state Suspend');
    writeln('8.  Call Set power state Off');
    writeln('9.  Restore defaults');
    writeln('ESC Exit');


    repeat
      gotoxy(1,24);
      showstatus;
      gotoxy(1,22);

      ch:=#0;
      if keypressed then
      begin

        gotoxy(1,22);
        for i:=1 to 79 do write(' ');
        gotoxy(1,22);

        ch:=readkey;
        repeat until port[$60] and 128=128;

        if ch='1' then idle;
        if ch='2' then busy;
        if ch='4' then enable;
        if ch='3' then disable;
        if ch='5' then setstate(0);
        if ch='6' then setstate(1);
        if ch='7' then setstate(2);
        if ch='8' then setstate(3);
        if ch='9' then restore;

        gotoxy(1,1);
        dispbasics;



      end;
    until ch=#27;

    write('Disconnect interface ');
    asm
      mov failed,true

      mov ax,5304h
      mov bx,0
      int 15h
      jc @exit

      mov failed,false

    @exit:
      mov err,ah
    end;
    if failed then showcode else writeln('OK');

    gotoxy(1,24);

  end else writeln('APM Not detected...');
end.
