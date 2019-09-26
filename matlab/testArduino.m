% runexperiment

port = 3;

runserialportserver(port,115200,300);

params.port = '3020';
params.server = 'localhost';
params.protocol = 'Arduino';
params.numcharacters = '116';
params.numvalues = '22';

pause(2);
sc = serialportclient(params,logfilegenerator);

sc = setupdevice(sc);

setupRecording(sc,'dummy.txt',100);

startSamplingWithoutRecording(sc);

pause(0.1);

d = getsample(sc);fprintf('%.2f,',d);fprintf('\n');
d = getsample(sc);fprintf('%.2f,',d);fprintf('\n');
d = getsample(sc);fprintf('%.2f,',d);fprintf('\n');
d = getsample(sc);fprintf('%.2f,',d);fprintf('\n');

stopRecording(sc);

closedevice(sc);