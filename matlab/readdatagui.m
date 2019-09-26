function varargout = readdatagui(varargin)
% READDATAGUI MATLAB code for readdatagui.fig
%      READDATAGUI, by itself, creates a new READDATAGUI or raises the existing
%      singleton*.
%
%      H = READDATAGUI returns the handle to a new READDATAGUI or the handle to
%      the existing singleton*.
%
%      READDATAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in READDATAGUI.M with the given input arguments.
%
%      READDATAGUI('Property','Value',...) creates a new READDATAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before readdatagui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to readdatagui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help readdatagui

% Last Modified by GUIDE v2.5 21-Jul-2016 10:58:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @readdatagui_OpeningFcn, ...
                   'gui_OutputFcn',  @readdatagui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before readdatagui is made visible.
function readdatagui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to readdatagui (see VARARGIN)

% Choose default command line output for readdatagui
handles.output = hObject;

handles.datasize = 116;
handles.values = NaN * ones(21,1);
handles.lastvalues = NaN * ones(3,1);

% Update handles structure
guidata(hObject, handles);

updateSerialPortList(handles);
set(handles.connectionStatus,'String','Disconnected');
updateValues(handles,hObject);

% UIWAIT makes readdatagui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function updateValues(handles,hObject)

for k=1:21
    set(handles.(['text' num2str(k)]),'String',sprintf('%d: %d',k,handles.values(k)));
end

holeThreshold = str2double(get(handles.holeThresholdInput,'String'));
containerThreshold = str2double(get(handles.containerThresholdInput,'String'));

% Update the buttons
for k=1:18
    set(handles.(['d' num2str(k)]),'Value',handles.values(k)>=holeThreshold);
end

% Update the container (if relative to the last frame, change of > 1
thisvalues(1:3,1) = handles.values(19:21);
set(handles.container,'Value',sum(abs(thisvalues - handles.lastvalues))>=containerThreshold);
handles.lastvalues = thisvalues;
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = readdatagui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in connectButton.
function connectButton_Callback(hObject, eventdata, handles)
% hObject    handle to connectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
portnumber = get(handles.serialPortList,'Value');
portnames = get(handles.serialPortList,'String');
port = portnames{portnumber};

COMport = port;
baudRate = 115200;

% Put inside a try so we can catch any errors
try
    if ispc
        [handles.s,errmsg] = IOPort('OpenSerialPort',sprintf('\\\\.\\%s',COMport),sprintf('BaudRate=%d,ReceiveTimeout=2.0',baudRate));
    else
        [handles.s,errmsg] = IOPort('OpenSerialPort',COMport,sprintf('BaudRate=%d,ReceiveTimeout=2.0',baudRate));
    end
catch err
    set(handles.connectionStatus,'String',err.message);
    return;
end

% Clear the buffer
dataread = IOPort('Read',handles.s,0);

pause(1);
% Put into mode 2 (only return data when requested)
[nwritten,when,errmsg] = IOPort('Write',handles.s,'2');
dataread = IOPort('Read',handles.s,1,3);
if numel(dataread)==0 || dataread(1)~= 50 
    set(handles.connectionStatus,'String','Error:could not connect');
    return;
end

set(handles.connectionStatus,'String','Connected');
guidata(hObject,handles);

% Set a timer to collect data
handles.timer = timer(...
    'ExecutionMode', 'fixedRate', ...  % Run timer repeatedly
    'Period', 0.02, ...                % 50 fps
    'TimerFcn', {@updatedata,handles.text1}); % Specify callback
start(handles.timer);
guidata(hObject,handles);

% --- Executes on button press in disconnectButton.
function disconnectButton_Callback(hObject, eventdata, handles)
% hObject    handle to disconnectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

IOPort('Close',handles.s);

% Stop the timer
if isfield(handles,'timer');
    stop(handles.timer);
    delete(handles.timer);
end

set(handles.connectionStatus,'String','Disconnected');



% Updates the data - called regularly by the timer
function updatedata(~,~,text1)

handles = guidata(text1);

% Request a frame of data
[nwritten,when,errmsg] = IOPort('Write',handles.s,'s');
pause(0.1);
dataread = IOPort('Read',handles.s,1,handles.datasize);

newdata = NaN * ones(22,1);
if numel(dataread)~=handles.datasize || dataread(1)~= 'P'
    % clear the buffer
    dataread
    fprintf('Clearing the buffer\n');
    dataread = IOPort('Read',handles.s,0);
else
    chardata = char(dataread);
    newdata = str2num(chardata(2:end));
end

handles.values = newdata;
updateValues(handles,handles.container);

% --- Executes on selection change in serialPortList.
function serialPortList_Callback(hObject, eventdata, handles)
% hObject    handle to serialPortList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns serialPortList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from serialPortList


% --- Executes during object creation, after setting all properties.
function serialPortList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to serialPortList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in refreshSerialPorts.
function refreshSerialPorts_Callback(hObject, eventdata, handles)
% hObject    handle to refreshSerialPorts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
updateSerialPortList(handles);

function updateSerialPortList(handles)

ports = getAvailableComPort;
set(handles.serialPortList,'String',ports);


% --- Executes on button press in closeAllSerial.
function closeAllSerial_Callback(hObject, eventdata, handles)
% hObject    handle to closeAllSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

IOPort('CloseAll');


% --- Executes on button press in container.
function container_Callback(hObject, eventdata, handles)
% hObject    handle to container (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of container



function holeThresholdInput_Callback(hObject, eventdata, handles)
% hObject    handle to holeThresholdInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of holeThresholdInput as text
%        str2double(get(hObject,'String')) returns contents of holeThresholdInput as a double


% --- Executes during object creation, after setting all properties.
function holeThresholdInput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to holeThresholdInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function containerThresholdInput_Callback(hObject, eventdata, handles)
% hObject    handle to containerThresholdInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of containerThresholdInput as text
%        str2double(get(hObject,'String')) returns contents of containerThresholdInput as a double


% --- Executes during object creation, after setting all properties.
function containerThresholdInput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to containerThresholdInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
