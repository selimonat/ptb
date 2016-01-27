function key = counterkeys(init,fileX,thephase,phasei)

switch init.(thephase{phasei}).hostname
    case 'triostim1'
        switch fileX.keycond
            case '1'
                key.in    = KbName('2@');%left
                key.out   = KbName('1!');%right
                key.old   = KbName('2@');
                key.new   = KbName('1!');
            case '2'
                key.in    = KbName('2@');
                key.out   = KbName('1!');
                key.old   = KbName('1!');
                key.new   = KbName('2@');
            case '3'
                key.in    = KbName('1!');
                key.out   = KbName('2@');
                key.old   = KbName('1!');
                key.new   = KbName('2@');
            case '4'
                key.in    = KbName('1!');
                key.out   = KbName('2@');
                key.old   = KbName('2@');
                key.new   = KbName('1!');
        end
        
    case 'etpc'
        error('add buttons for eye link lab')
        
    case 'isnf01faf2bafa4'
        
        switch fileX.keycond
            case '1'
                key.in    = KbName('LeftArrow');
                key.out   = KbName('DownArrow');
                key.old   = KbName('LeftArrow');
                key.new   = KbName('DownArrow');
            case '2'
                key.in    = KbName('LeftArrow');
                key.out   = KbName('DownArrow');
                key.old   = KbName('DownArrow');
                key.new   = KbName('LeftArrow');
            case '3'
                key.in    = KbName('DownArrow');
                key.out   = KbName('LeftArrow');
                key.old   = KbName('DownArrow');
                key.new   = KbName('LeftArrow');
            case '4'
                key.in    = KbName('DownArrow');
                key.out   = KbName('LeftArrow');
                key.old   = KbName('LeftArrow');
                key.new   = KbName('DownArrow');
        end

end