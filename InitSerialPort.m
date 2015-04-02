function [port]=InitSerialPort

%
port = IOPort('OpenSerialPort', 'COM1', 'InputBufferSize=51840000 HardwareBufferSizes=32768,32768 Terminator=0 ReceiveLatency=0.0001 BaudRate=9600 ReceiveTimeout=7');
IOPort('ConfigureSerialPort', port, 'BlockingBackgroundRead=1');
%because of the BlockingBackgroundRead=1, the flush and close all
%command will wait for the next byte to arrive...
IOPort('Purge', port);
IOPort('ConfigureSerialPort', port, 'StartBackgroundRead=2');