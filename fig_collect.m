function fig_collect
%FIG_COLLECT Window for the collection of ratings
% License: https://darma.codeplex.com/license

    % Create and center main window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_collect = figure( ...
        'Units','normalized', ...
        'Name','DARMA: Collect', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'NumberTitle','off', ...
        'Visible','off', ...
        'Color',defaultBackground, ...
        'SizeChangedFcn',@figure_collect_SizeChanged, ...
        'KeyPressFcn',@figure_collect_KeyPress, ...
        'CloseRequestFcn',@figure_collect_CloseReq);
    % Create menu bar elements
    handles.menu_media = uimenu(handles.figure_collect, ...
        'Parent',handles.figure_collect, ...
        'Label','Open Multimedia File', ...
        'Callback',@menu_media_Callback);
    handles.menu_preview = uimenu(handles.figure_collect, ...
        'Parent',handles.figure_collect, ...
        'Label','Preview Multimedia File', ...
        'Enable','off', ...
        'Callback',@menu_preview_Callback);
    handles.menu_help = uimenu(handles.figure_collect, ...
        'Parent',handles.figure_collect, ...
        'Label','Help');
    handles.menu_about = uimenu(handles.menu_help, ...
        'Parent',handles.menu_help, ...
        'Label','About', ...
        'Callback',@menu_about_Callback);
    handles.menu_document = uimenu(handles.menu_help, ...
        'Parent',handles.menu_help, ...
        'Label','Documentation', ...
        'Callback',@menu_document_Callback);
    handles.menu_report = uimenu(handles.menu_help, ...
        'Parent',handles.menu_help, ...
        'Label','Report Issues', ...
        'Callback',@menu_report_Callback);
    pause(0.1);
    set(handles.figure_collect,'Position',[0.1 0.1 0.8 0.8]);
    % Create uicontrol elements
    handles.text_report = uicontrol('Style','edit', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.01 .02 .22 .05], ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.text_filename = uicontrol('Style','edit', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.24 .02 .40 .05], ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.text_duration = uicontrol('Style','edit', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.65 .02 .22 .05], ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.toggle_playpause = uicontrol('Style','togglebutton', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.88 .02 .11 .05], ...
        'String','Begin Rating', ...
        'FontSize',14.0, ...
        'Callback',@toggle_playpause_Callback, ...
        'Enable','off');
    handles.axis_guide = axes('Units','normalized', ...
        'Parent',handles.figure_collect, ...
        'Position',[.01 .09 .63 .89], ...
        'Box','on','XTick',[],'YTick',[],'Color','black');
    handles.axis_circle = axes('Units','normalized', ...
        'Parent',handles.figure_collect, ...
        'OuterPosition',[.65 .09 .34 .89], ...
        'LooseInset',[0 0 0 0], ...
        'XLim',[-1,1],'YLim',[-1,1], ...
        'NextPlot','add', ...
        'Box','on','XTick',[],'YTick',[],'Layer','top');
    axis square;
    % Invoke and configure VLC ActiveX Controller
    handles.vlc = actxcontrol('VideoLAN.VLCPlugin.2',getpixelposition(handles.axis_guide),handles.figure_collect);
    handles.vlc.AutoPlay = 0;
    handles.vlc.Toolbar = 0;
    handles.vlc.FullscreenEnabled = 0;
    try
        handles.joy = vrjoystick(1);
    catch
        e = errordlg('DARMA could not detect a joystick.','Error','modal');
        waitfor(e);
        return;
    end
    % Create timer
    handles.recording = 0;
    handles.timer = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',0.05, ...
        'TimerFcn',{@timer_Callback,handles}, ...
        'ErrorFcn',{@timer_ErrorFcn,handles});
    % Start system clock to improve VLC time stamp precision
    global global_tic recording;
    global_tic = tic;
    recording = 0;
    % Save handles to guidata
    handles.figure_collect.Visible = 'on';
    guidata(handles.figure_collect,handles);
    create_axis(handles);
    addpath('Functions');
    start(handles.timer);
end

% =========================================================

function menu_media_Callback(hObject,~)
    handles = guidata(hObject);
    % Reset the GUI elements
    program_reset(handles);
    global settings ratings last_ts_vlc last_ts_sys;
    ratings = [];
    last_ts_vlc = 0;
    last_ts_sys = 0;
    handles.vlc.playlist.items.clear();
    % Browse for, load, and get text_duration for a media file
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file',fullfile(settings.folder));
    if video_name==0, return; end
    try
        MRL = fullfile(video_path,video_name);
        handles.VID = MRL;
        MRL(MRL=='\') = '/';
        handles.MRL = sprintf('file://localhost/%s',MRL);
        handles.vlc.playlist.add(handles.MRL);
        handles.vlc.playlist.play();
        while handles.vlc.input.state ~= 3
            pause(0.001);
        end
        handles.vlc.playlist.togglePause();
        handles.vlc.input.time = 0;
        handles.dur = handles.vlc.input.length / 1000;
        if handles.dur == 0
            handles.vlc.playlist.items.clear();
            error('Could not read duration of media file. The file meta-data may be damaged. Transcoding the streams (e.g., with HandBrake) may fix this problem.');
        end
    catch err
        msgbox(err.message,'Error loading media file.'); return;
    end
    % Update GUI elements
    set(handles.text_filename,'String',video_name);
    set(handles.text_duration,'String',datestr(handles.dur/24/3600,'HH:MM:SS'));
    set(handles.toggle_playpause,'Enable','On');
    set(handles.menu_preview,'Enable','On');
    guidata(hObject,handles);
end

% =========================================================

function menu_preview_Callback(hObject,~)
    handles = guidata(hObject);
    winopen(handles.VID);
end
% ===============================================================================

function menu_about_Callback(~,~)
    global version;
    msgbox(sprintf('DARMA version %.2f\nJeffrey M Girard (c) 2014-2016\nhttp://darma.codeplex.com\nGNU General Public License v3',version),'About','Help');
end

% ===============================================================================

function menu_document_Callback(~,~)
    web('http://darma.codeplex.com/documentation','-browser');
end

% ===============================================================================

function menu_report_Callback(~,~)
    web('http://darma.codeplex.com/discussions','-browser');
end

% =========================================================

function figure_collect_KeyPress(hObject,eventdata)
    handles = guidata(hObject);
    global recording;
    % Escape if the playpause button is disabled
    if strcmp(get(handles.toggle_playpause,'enable'),'inactive'), return; end
    % Pause playback if the pressed key is spacebar
    if strcmp(eventdata.Key,'space') && get(handles.toggle_playpause,'value')
        handles.vlc.playlist.togglePause();
        recording = 0;
        set(handles.toggle_playpause,'String','Resume Rating','Value',0);
    else
        return;
    end
    guidata(hObject,handles);
end

% =========================================================

function toggle_playpause_Callback(hObject,~)
    handles = guidata(hObject);
    global recording;
    if get(hObject,'Value')
        % If toggle button is set to play, update GUI elements
        set(hObject,'Enable','Off','String','...');
        set(handles.menu_media,'Enable','off');
        set(handles.menu_preview,'Enable','off');
        % Start three second countdown before starting
        set(handles.text_report,'String','...3...'); pause(1);
        set(handles.text_report,'String','..2..'); pause(1);
        set(handles.text_report,'String','.1.'); pause(1);
        set(hObject,'Enable','On','String','Pause Rating');
        recording = 1;
        guidata(hObject,handles);
        % Send play() command to VLC and wait for it to start playing
        handles.vlc.playlist.play();
    else
        % If toggle button is set to pause, send pause() command to VLC
        handles.vlc.playlist.togglePause();
        recording = 0;
        set(hObject,'String','Resume Rating','Value',0);
        guidata(hObject,handles);
    end
end

% =========================================================

function timer_Callback(~,~,handles)
    handles = guidata(handles.figure_collect);
    global settings ratings last_ts_vlc last_ts_sys global_tic marker recording;
    % Before playing
    if recording == 0
        [a,b,~] = read(handles.joy);
        x = a(1); y = a(2)*-1;
        if b(1)==0, color = 'w'; else color = 'y'; end
        set(marker,'XData',x,'YData',y,'MarkerFace',color);
        return;
    end
    % While playing
    if handles.vlc.input.state == 3
        try
            % Read status of the joystick
            [a,b,~] = read(handles.joy);
        catch
            %If failed, recreate the joystick
            handles.joy = vrjoystick(1);
            guidata(handles.figure_collect,handles);
            return;
        end
        ts_vlc = handles.vlc.input.time/1000;
        ts_sys = toc(global_tic);
        if ts_vlc == last_ts_vlc && last_ts_vlc ~= 0
            ts_diff = ts_sys - last_ts_sys;
            ts_vlc = ts_vlc + ts_diff;
        else
            last_ts_vlc = ts_vlc;
            last_ts_sys = ts_sys;
        end
        x = a(1); y = a(2)*-1;
        if b(1)==0, color = 'r'; else color = 'g'; end
        set(marker,'XData',x,'YData',y,'MarkerFace',color);
        ratings = [ratings; ts_vlc,x*settings.mag,y*settings.mag,b(1)];
        set(handles.text_report,'string',datestr(handles.vlc.input.time/1000/24/3600,'HH:MM:SS'));
        drawnow();
        guidata(handles.figure_collect,handles);
    % After playing
    elseif handles.vlc.input.state == 5 || handles.vlc.input.state == 6
        recording = 0;
        handles.vlc.playlist.stop();
        set(handles.toggle_playpause,'Value',0);
        set(handles.text_report,'string','Processing...');
        % Average ratings per second of playback
        rating = ratings;
        disp(rating);
        anchors = [0,(settings.bin:settings.bin:floor(handles.dur))];
        mean_ratings = nan(length(anchors)-1,4);
        mean_ratings(:,1) = anchors(2:end)';
        for i = 1:length(anchors)-1
            s_start = anchors(i);
            s_end = anchors(i+1);
            index = (rating(:,1) >= s_start) & (rating(:,1) < s_end);
            bin = rating(index,2:end);
            if isempty(bin), continue; end
            mean_ratings(i,:) = [s_end,nanmean(bin(:,1)),nanmean(bin(:,2)),nanmax(bin(:,3))];
        end
        disp(mean_ratings);
        % Prompt user to save the collected annotations
        [~,defaultname,ext] = fileparts(handles.MRL);
        [filename,pathname] = uiputfile({'*.csv','Comma-Separated Values (*.csv)'},'Save as',fullfile(settings.folder,defaultname));
        if ~isequal(filename,0) && ~isequal(pathname,0)
            % Add metadata to mean ratings and timestamps
            output = [ ...
                {'Time of Rating'},{datestr(now)},{''},{''}; ...
                {'Multimedia File'},{sprintf('%s%s',defaultname,ext)},{''},{''}; ...
                {'Magnitude'},{settings.mag},{''},{''}; ...
                {'Second'},{settings.labelX},{settings.labelY},{'Button'}; ...
                {'%%%%%%'},{'%%%%%%'},{'%%%%%%'},{'%%%%%%'}; ...
                num2cell(mean_ratings)];
            % Create export file depending on selected file type
            success = cell2csv(fullfile(pathname,filename),output);
            % Report saving success or failure
            if success
                h = msgbox('Export successful.');
                waitfor(h);
            else
                h = msgbox('Export error.');
                waitfor(h);
            end
        end
        program_reset(handles);
    % While transitioning or paused
    else
        return;
    end
end

% =========================================================

function timer_ErrorFcn(hObject,event,handles)
    disp(event.Data);
    handles = guidata(handles.figure_collect);
    global settings ratings;
    handles.vlc.playlist.togglePause();
    stop(handles.timer);
    msgbox(sprintf('Timer callback error:\n%s\nAn error log has been saved.',event.Data.message),'Error','error');
    csvwrite(fullfile(settings.folder,sprintf('%s.csv',datestr(now,30))),ratings);
    guidata(handles.figure_collect,handles);
end

% =========================================================

function create_axis(handles)
    handles = guidata(handles.figure_collect);
    global settings marker;
    axes(handles.axis_circle);
    plot(handles.axis_circle,[-1,1],[0,0],'k-');
    plot(handles.axis_circle,[0,0],[-1,1],'k-');
    text(0.0,0.9,settings.label1,'HorizontalAlignment','center','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5);
    text(-0.64,0.64,settings.label2,'HorizontalAlignment','center','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5);
    text(0.64,0.64,settings.label3,'HorizontalAlignment','center','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5); 
    text(-0.9,0.0,settings.label4,'HorizontalAlignment','left','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5);
    text(0.9,0.0,settings.label5,'HorizontalAlignment','right','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5);
    text(-0.64,-0.64,settings.label6,'HorizontalAlignment','center','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5);
    text(0.64,-0.64,settings.label7,'HorizontalAlignment','center','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5);
    text(0.0,-0.9,settings.label8,'HorizontalAlignment','center','BackgroundColor',[1 1 1],'FontSize',12,'Margin',5);
    marker = plot(handles.axis_circle,0,0,'ko','LineWidth',2,'MarkerSize',15,'MarkerFaceColor','white');
    guidata(handles.figure_collect,handles);
end

% =========================================================

function figure_collect_SizeChanged(hObject,~)
    handles = guidata(hObject);
    if isfield(handles,'figure_collect')
        pos = getpixelposition(handles.figure_collect);
        % Force to remain above a minimum size
        if pos(3) < 1024 || pos(4) < 600
            setpixelposition(handles.figure_collect,[pos(1) pos(2) 1024 600]);
            movegui(handles.figure_collect,'center');
        end
        % Update the size and position of the VLC controller
        if isfield(handles,'vlc')
            move(handles.vlc,getpixelposition(handles.axis_guide));
        end
    end
end

% =========================================================

function figure_collect_CloseReq(hObject,~)
    handles = guidata(hObject);
    global recording;
    % Pause playback and rating
    if handles.vlc.input.state==3,handles.vlc.playlist.togglePause(); end
    set(handles.toggle_playpause,'String','Resume Rating','Value',0);
    recording = 0;
    guidata(handles.figure_collect,handles);
    pause(.1); 
    if handles.vlc.input.state==4
        %If ratings are being collected, prompt user to cancel them
        choice = questdlg('Do you want to cancel your current ratings?', ...
            'DARMA','Yes','No','No');
        switch choice
            case 'Yes'
                handles.vlc.playlist.stop();
                program_reset(handles);
            case 'No'
                return;
        end
    else
        %If ratings are not being collected, exit DARMA
        if strcmp(handles.timer.Running,'on'), stop(handles.timer); end
        delete(handles.timer);
        delete(handles.figure_collect);
    end
end

% =========================================================

function program_reset(handles)
    global recording;
    handles = guidata(handles.figure_collect);
    recording = 0;
    % Update GUI elements to starting configuration
    set(handles.text_report,'String','');
    set(handles.text_filename,'String','');
    set(handles.text_duration,'String','');
    set(handles.toggle_playpause,'Enable','off','String','Begin Rating');
    set(handles.menu_media,'Enable','on');
    set(handles.menu_preview,'Enable','off');
    guidata(handles.figure_collect,handles);
end
