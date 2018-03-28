function SLMmodule

% Software for generating phase hologram input to SLM to be used in
% conjunction with Femtonics MES system
% Written by Ann Go; Edited by Ann Go and Michael Castanares
% Last modified: 10 Jan 2018


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%            DEFINITIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sample_image = 'sampleneuron_doNOTdelete.jpg';
release = version('-release'); % Find out what Matlab release version is running
MatlabVer = str2double(release(1:4));
if MatlabVer > 2016
    MatlabVer = 2016;
end

% Possible error messages
error_SLMdisconnect = 'There was an error opening the SLM display. It might not be connected or Psychtoolbox might not be installed.';
error_MESnotrunning = 'This program cannot run in Experiment mode if MES is not running.';
error_widthStep = strcat('The image widthstep(\mu','m/pix)could not be obtained from MES. MES may not be open.');
error_no2Pimage = 'No two-photon image has been taken. Take image first.';
%error_noSampleImage = 'The file "sampleneuron_doNOTdelete.jpg" is missing from the SLM_software folder. Change filename in Matlab code (Line 11) with desired sample image.';
error_outofrangeLambda = 'Invalid wavelength. Operational wavelength range for SLM is 750-850 nm.';
error_nonnumericLambda = 'Invalid wavelength. Enter numeric wavelength.';
error_nonnumericCoords = 'Invalid spot coordinates or L value. Enter numeric values.';
error_nonnumericXYshift = 'Invalid z or x and y shift values. Enter numeric values.';
error_nonnumericZcoeffs = 'Invalid Zernike polynomial coefficients. Enter numeric values.';
error_nonnumericStep = 'Invalid step size. Enter a number.';
error_noActiveSites = 'There are no active uncaging sites. Activate at least one.';
error_wrongSpotLocationsFile = 'The file you selected is incorrect. Choose another file.';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            ARCHITECTURE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% GUI figure
hfig_h = 380;
if MatlabVer == 2016
    hfig_w = 225;
elseif MatlabVer == 2010
    hfig_w = 225;
else
    hfig_w = 220;
end
tabgrp_h = hfig_h-25;

hfig = figure('MenuBar','none','Name','SLM','NumberTitle','off','Resize','off',...
    'Position',[1680-2*hfig_w,1050-hfig_h,hfig_w,hfig_h]);
if MatlabVer == 2007
    movegui(hfig,[-236 -05]);
else
    movegui('northeast');
end

htabgroup = uitabgroup('Parent',hfig,'Units','Pix','Position',[0 0 hfig_w hfig_h]);
    tab1 = uitab(htabgroup,'Title','Uncage'); 
    tab2 = uitab(htabgroup,'Title','Calibrate'); 
    tab3 = uitab(htabgroup,'Title','Correct');
    tab4 = uitab(htabgroup,'Title','Settings');
if MatlabVer == 2016
    set(htabgroup,'Position',[-5,0,235,380]);
end
    
try % For R2014b and later
    set(htabgroup,'SelectionChangedFcn',@tab_select_change);
    set(htabgroup,'SelectedTab',tab4);
catch % For releases before R2014b
    set(htabgroup,'SelectionChangeFcn',@tab_select_change);
    set(htabgroup,'SelectedIndex',4);
end


% TAB 1: UNCAGING
panel_fw = 215;
table_h = 190;
Nmin = 0;
Nmax = 50;
t1panel_h = table_h + 55;

% Panel 1 (N spots spinner)
t1panel = uipanel('Parent',tab1,'Units','Pix',...
    'Position',[3 tabgrp_h-t1panel_h-0 panel_fw t1panel_h]);
    if MatlabVer == 2016
        set(t1panel,'Position',[3 tabgrp_h-t1panel_h-5 panel_fw-2 t1panel_h]);
    end
[spinner_Nspots,spinner_Nspots_ud] = spinner('Parent',tab1,'Position',[85 hfig_h-50 50 20],...
    'Startvalue',0,'Min',Nmin,'Max',Nmax,'Step',1);
    set(spinner_Nspots,'Enable','off');
uicontrol('Parent',t1panel,'Style','Text','String','No. of spots:',...
    'Position',[10, t1panel_h-30, 70, 20],'HorizontalAlignment','left','Fontsize',8);

set(spinner_Nspots_ud(1),'Callback',@spinner_Nspots_dec_Callback);
set(spinner_Nspots_ud(2),'Callback',@spinner_Nspots_inc_Callback);

% Table of spot coordinates
    % Version-specific properties
    switch MatlabVer
        case 2016 % Tested with R2016a
            table_coords = createTable(t1panel,{'<html><sub>\</sub><i>/</i></html>','x','y','z','L'},{},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',true,...
                'DataChangedCallback',@table_coords_DataChangedCallback,...
                'Position',[11,hfig_h-15-table_h-25,panel_fw-10,table_h]);
        case 2015 % Tested with R2015a
            table_coords = createTable(t1panel,{'<html><sub>\</sub><i>/</i></html>','x','y','z','L'},{},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',true,...
                'DataChangedCallback',@table_coords_DataChangedCallback,...
                'Position',[6,hfig_h-25-table_h-25,panel_fw-5,table_h]);
        case 2010 % Tested with R2010a
            table_coords = createTable(t1panel,{'<html><sub>\</sub><i>/</i></html>','x','y','z','L'},{},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',true,...
                'DataChangedCallback',@table_coords_DataChangedCallback,...
                'Position',[7,hfig_h-25-table_h-25,panel_fw-5,table_h]);
        case 2007 % Tested with R2007
            table_coords = createTable(t1panel,{'<html><sub>\</sub><i>/</i></html>','x','y','z','L'},{},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',true,...
                'DataChangedCallback',@table_coords_DataChangedCallback,...
                'Position',[8,hfig_h-25-table_h-25,panel_fw-5,table_h]);
    end

table_coords.setCheckBoxEditor(1); % Set 1st column to check box.
jtable_coords = table_coords.getTable;
jtable_coords.getColumnModel.getColumn(0).setMaxWidth(28);
jtable_coords.getColumnModel.getColumn(3).setMaxWidth(45);
jtable_coords.getColumnModel.getColumn(4).setMaxWidth(35);


% Push buttons for table (Activate all spots, Add spot, Delete spot)
pbutton_addSpot = uicontrol('Parent',t1panel,'unit','pix',...
    'position',[5 5 28 20],'string','Add','Enable','on',...
    'Callback',@pbutton_addSpot_press,'Fontsize',8);
pbutton_delSpot = uicontrol('Parent',t1panel,'unit','pix',...
    'position',[35 5 40 20],'string','Delete','Enable','off',...
    'Callback',@pbutton_delSpot_press,'Fontsize',8);
pbutton_activateAllSpots = uicontrol('Parent',t1panel,'unit','pix',...
    'position',[77 5 60 20],'string','Activate all','Enable','off',...
    'Callback',@pbutton_activateAllSpots_press,'Fontsize',8);
pbutton_saveSpots = uicontrol('Parent',t1panel,'unit','pix',...
    'position',[139 5 36 20],'string','SAVE','Enable','off',...
    'Callback',@pbutton_saveSpots_press,'Fontsize',8);
pbutton_loadSpots = uicontrol('Parent',t1panel,'unit','pix',...
    'position',[177 5 33 20],'string','Load','Enable','on',...
    'Callback',@pbutton_loadSpots_press,'Fontsize',8);


% Check boxes (Cursor control, Show spot labels)
check_cursorCtrl = uicontrol('Parent',tab1,'style','check','unit','pix',...
    'position',[5 hfig_h-t1panel_h-45 200 20],'string','Cursor control',...
    'Callback',@check_cursorCtrl_Callback,'Fontsize',8);
check_showUncagingArea = uicontrol('Parent',tab1,'style','check','unit','pix','value',1,'Enable','on',...
    'position',[102 hfig_h-t1panel_h-45 200 20],'string','Show uncaging area',...
    'Callback',@check_showUncagingArea_Callback,'Fontsize',8);
check_showLabels = uicontrol('Parent',tab1,'style','check','unit','pix',...
    'position',[5 hfig_h-t1panel_h-60 200 20],'string','Spot labels',...
    'Enable','on','Callback',@check_showLabels_Callback,'Fontsize',8);
check_showRefLines = uicontrol('Parent',tab1,'style','check','unit','pix',...
    'position',[102 hfig_h-t1panel_h-60 200 20],'string','Show ref lines',...
    'Enable','on','Callback',@check_showUncagingArea_Callback,'Fontsize',8);
uicontrol('Parent',tab1,'String','Drift correction','Units','pixels',...
    'Position',[60 hfig_h-t1panel_h-80 100 20],'Callback',@pbutton_driftCorr_press,...
    'Fontsize',8);
text_warn = uicontrol('Parent',tab1,'Style',...
    'Text','String','Note: Continuous hologram update and table editing of x and y are currently disabled.',...
    'Position',[10, hfig_h-t1panel_h-115, 203, 30],'HorizontalAlignment','left',...
    'FontSize',7,'Visible','off');

    
% Push buttons (Blank hologram, Update Image, Update hologram, Continuous holo)
pbutton_updateHolo = uicontrol('Parent',hfig,'String','Update hologram',...
    'Units','pixels','Position',[5 5 105 25],'Visible','off',...
    'Callback',@pbutton_updateHolo_press,'Fontsize',8);
toggle_contHolo = uicontrol('Parent',hfig,'String','<html>Continuous holo',...
    'Units','pixels','Position',[112 5 105 25],'Style','ToggleButton',...
    'Visible','off','Callback',@contHolo_toggle,'Fontsize',8);
pbutton_blankHolo = uicontrol('Parent',hfig,'String','Blank hologram',...
    'Units','pixels','Position',[5 30 105 25],'Visible','off',...
    'Callback',@pbutton_blankHolo_press,'Fontsize',8);
pbutton_updateImage = uicontrol('Parent',hfig,'String','Update image',...
    'Units','pixels','Position',[112 30 105 25],'Visible','off',...
    'Callback',@pbutton_updateImage_press,'Fontsize',8);
    
    
% TAB 2: CALIBRATION

% X, Y, Z scaling and step size
edit_stepXYZ = uicontrol('Parent',tab2,'style','edit','unit','pix','string','0.1',...
    'Enable','off','BackgroundColor',[1 1 1],'Callback',@edit_stepXYZ_Callback,...
    'Fontsize',8);      
uicontrol('Parent',tab2,'Style','Text','String','Step:',...
        'Position',[35, tabgrp_h-107, 25, 17],'HorizontalAlignment','left',...
        'Fontsize',8,'Enable','on');
stepXYZ = str2double(get(edit_stepXYZ,'String'));

    % Version-specific properties    
    if MatlabVer == 2007 % Tested with R2007
        set(edit_stepXYZ,'Position',[70 tabgrp_h-105 34 17]);
    else % Tested with R2010a and R2015a
        set(edit_stepXYZ,'Position',[70 tabgrp_h-105 34 19]);
    end

[spinner_Xscale,spinner_Xscale_ud] = spinner('Parent',tab2,'Position',[70 tabgrp_h-42 50 20],...
    'Startvalue',1,'Min',0,'Max',10,'Step',stepXYZ,'Callback',@spinner_Xscale_Callback);
    set(spinner_Xscale,'Enable','off');
    set(spinner_Xscale_ud(1),'Enable','on');
    set(spinner_Xscale_ud(2),'Enable','on');
uicontrol('Parent',tab2,'Style','Text','String','X scaling',...
    'Position',[15, tabgrp_h-45, 50, 20],'HorizontalAlignment','left','Enable','on',...
    'Fontsize',8);

[spinner_Yscale,spinner_Yscale_ud] = spinner('Parent',tab2,'Position',[70 tabgrp_h-62 50 20],...
    'Startvalue',1,'Min',0,'Max',10,'Step',stepXYZ,'Callback',@spinner_Yscale_Callback);
    set(spinner_Yscale,'Enable','off');
    set(spinner_Yscale_ud(1),'Enable','on');
    set(spinner_Yscale_ud(2),'Enable','on');
uicontrol('Parent',tab2,'Style','Text','String','Y scaling',...
    'Position',[15, tabgrp_h-65, 50, 20],'HorizontalAlignment','left','Enable','on',...
    'Fontsize',8);

[spinner_Zscale,spinner_Zscale_ud] = spinner('Parent',tab2,'Position',[70 tabgrp_h-82 50 20],...
    'Startvalue',1,'Min',0,'Max',10,'Step',stepXYZ,'Callback',@spinner_Zscale_Callback);
    set(spinner_Zscale,'Enable','off');
    set(spinner_Zscale_ud(1),'Enable','on');
    set(spinner_Zscale_ud(2),'Enable','on');
uicontrol('Parent',tab2,'Style','Text','String','Z scaling',...
    'Position',[15, tabgrp_h-85, 50, 20],'HorizontalAlignment','left','Enable','on',...
    'Fontsize',8);

% Rotation scaling spinner and step size
edit_stepA = uicontrol('Parent',tab2,'style','edit','unit','pix','String','0.5',...
    'Enable','off','BackgroundColor',[1 1 1],'Callback',@edit_stepA_Callback,...
    'Fontsize',8);
uicontrol('Parent',tab2,'Style','Text','String','Step:',...
    'Position',[140, tabgrp_h-107, 25, 17],'HorizontalAlignment','left','Enable','on',...
    'Fontsize',8);
stepA = str2double(get(edit_stepA,'String'));

    % Version-specific properties
    if MatlabVer == 2007
        set(edit_stepA,'Position',[172 tabgrp_h-105 34 17]);  
    else
        set(edit_stepA,'Position',[172 tabgrp_h-105 34 19]);
    end

[spinner_angle,spinner_angle_ud] = spinner('Parent',tab2,'Position',[150 tabgrp_h-75 50 20],...
    'Startvalue',0,'Min',-90,'Max',90,'Step',stepA,'Callback',@spinner_angle_Callback);
    set(spinner_angle,'Enable','off');
    set(spinner_angle_ud(1),'Enable','on');
    set(spinner_angle_ud(2),'Enable','on');
label_spinner_angle = uicontrol('Parent',tab2,'Style','Text','String','Rotation Angle °',...
    'HorizontalAlignment','left','Enable','on','Fontsize',8);

    % Version-specific properties    
    if MatlabVer == 2015 % Tested with R2015a
        set(label_spinner_angle,'Position',[155, tabgrp_h-55, 45, 30]);
    elseif MatlabVer == 2010 % Tested with R2010a
        set(label_spinner_angle,'Position',[155, tabgrp_h-55, 40, 30]);
    else % Tested with R2007
        set(label_spinner_angle,'Position',[155, tabgrp_h-55, 40, 30]);
    end

% Axial tilt correction
uicontrol('Parent',tab2,'Style','Text','String','Axial tilt correction:',...
        'Position',[10, tabgrp_h-135, 95, 17],'HorizontalAlignment','left',...
        'Fontsize',8,'Enable','on');

% Table of xy shift values for axial tilt correction
    % Version-specific properties
    table_xyShift_h = 66;
    switch MatlabVer
        case 2016 % Tested with R2016a
            table_xyShift = createTable(tab2,{'<html><sub>\</sub><i>/</i></html>','z','x shift','y shift'},...
                {false,'5','0','0'; false,'-5','0','0'},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',false,...
                'DataChangedCallback',@table_xyShift_DataChangedCallback,...
                'Position',[11,hfig_h-15-table_xyShift_h-135,panel_fw-10,table_xyShift_h]);
        case 2015 
            table_xyShift = createTable(tab2,{'<html><sub>\</sub><i>/</i></html>','z','x shift','y shift'},...
                {false,'5','0','0'; false,'-5','0','0'},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',false,...
                'DataChangedCallback',@table_xyShift_DataChangedCallback,...
                'Position',[6,hfig_h-15-table_xyShift_h-135,panel_fw-5,table_xyShift_h]);
        case 2010 
            table_xyShift = createTable(tab2,{'<html><sub>\</sub><i>/</i></html>','z','x shift','y shift'},...
                {false,'5','0','0'; false,'-5','0','0'},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',false,...
                'DataChangedCallback',@table_xyShift_DataChangedCallback,...
                'Position',[7,hfig_h-15-table_xyShift_h-140,panel_fw,table_xyShift_h-6]);
        case 2007 
            table_xyShift = createTable(tab2,{'<html><sub>\</sub><i>/</i></html>','z','x shift','y shift'},...
                {false,'5','0','0'; false,'-5','0','0'},...
                'Buttons',false,'Visible',false,'Units','pix','Editable',false,...
                'DataChangedCallback',@table_xyShift_DataChangedCallback,...
                'Position',[8,hfig_h-15-table_xyShift_h-140,panel_fw,table_xyShift_h-6]);
    end

table_xyShift.setCheckBoxEditor(1); % Set 1st column to check box.
jtable_xyShift = table_xyShift.getTable;
jtable_xyShift.getColumnModel.getColumn(0).setMaxWidth(28);
renderer = javax.swing.table.DefaultTableCellRenderer;
renderer.setForeground(java.awt.Color.lightGray);
renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
for i = 1:3
    jtable_xyShift.getColumnModel.getColumn(i).setCellRenderer(renderer);
end

% Amplitude weighting
uicontrol('Parent',tab2,'Style','Text','String','Amplitude weighting:',...
        'Position',[10, tabgrp_h-225, 150, 17],'HorizontalAlignment','left',...
        'Fontsize',8,'Enable','on');
check_xAmpWeight = uicontrol('Parent',tab2,'style','check','unit','pix',...
    'position',[15, tabgrp_h-242 60 20],'string','x',...
    'Enable','off','Callback',@check_AmpWeight_Callback,'Fontsize',8);
check_yAmpWeight1 = uicontrol('Parent',tab2,'style','check','unit','pix',...
    'position',[60, tabgrp_h-242 80 20],'string','y - linear',...
    'Enable','off','Callback',@check_yAmpWeight1_Callback,'Fontsize',8);
check_yAmpWeight2 = uicontrol('Parent',tab2,'style','check','unit','pix',...
    'position',[60, tabgrp_h-260 100 20],'string','y - sinc squared',...
    'Enable','off','Callback',@check_yAmpWeight2_Callback,'Fontsize',8);
check_zAmpWeight = uicontrol('Parent',tab2,'style','check','unit','pix',...
    'position',[170, tabgrp_h-242 60 20],'string','z',...
    'Enable','off','Callback',@check_AmpWeight_Callback,'Fontsize',8);


% Push buttons for Save calibration, Measure distance and Reset calibration  
uicontrol('Parent',tab2,'String','SAVE','Fontsize',8,...
    'Units','pixels','Position',[6 tabgrp_h-290 50 25],'Callback',@pbutton_saveCalib_press);
toggle_measureDist = uicontrol('Parent',tab2,'String','<html>Measure distance','Style','ToggleButton',...
    'Units','pixels','Position',[61 tabgrp_h-290 100 25],'Fontsize',8,...
    'Visible','on','Callback',@measureDist_toggle);
uicontrol('Parent',tab2,'String','<html>Reset',...
    'Units','pixels','Position',[165 tabgrp_h-290 50 25],'Visible','on',...
    'Callback',@pbutton_resetCalib_press,'Fontsize',8);


% TAB 3

table_h2 = 230;
check_disableCorr = uicontrol('Parent',tab3,'style','check','unit','pix','Value',0,...
    'position',[10 tabgrp_h-25 180 20],'string','Disable correction',...
    'Callback',@check_disableCorr_Callback);
    % Version-specific properties
    if MatlabVer ~= 2007
        set(check_disableCorr,'Fontsize',8);
    end
    if MatlabVer == 2016
        set(check_disableCorr,'position',[10 tabgrp_h-40 180 20]);
    end
check_uniformCorr = uicontrol('Parent',tab3,'style','check','unit','pix','Value',1,...
    'position',[10 tabgrp_h-45 180 20],'string','Uniform correction for all spots',...
    'Callback',@check_uniformCorr_Callback);
    % Version-specific properties
    if MatlabVer ~= 2007
        set(check_uniformCorr,'Fontsize',8);
    end
    if MatlabVer == 2016
        set(check_uniformCorr,'position',[10 tabgrp_h-60 180 20]);
    end

% Table of Zernike coefficients
listModel = {'Piston',...
            'Tip (x)',...
            'Tilt (y)',...
            'Defocus',...
            'Obl astig',...
            'Vert astig',...
            'Vert coma',...
            'Hori coma',...
            'Vert trefoil',...
            'Obl trefoil',...
            'Prim spher'};

switch MatlabVer
    case 2016
        table_Zcoeff = createTable(tab3,{'All','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'},...
            {'0', '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0'},...
            'Buttons',false,'Visible',false,...
            'AutoResizeMode',javax.swing.JTable.AUTO_RESIZE_OFF,... % Do not adjust column widths automatically; use a scrollbar.
            'Units','pix','Position',[5,tabgrp_h-table_h2-45,panel_fw,table_h2-8],...
            'Editable',true,'DataChangedCallback',@table_Zcoeff_DataChangedCallback,...
            'ColumnWidth',29);
        jtable_Zcoeff = table_Zcoeff.getTable;
        jtable_Zcoeff.setRowHeight(16);
        renderer = javax.swing.table.DefaultTableCellRenderer;
        renderer.setForeground(java.awt.Color.lightGray);
        renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        for i = 0:20 % java indexing
            jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
            table_Zcoeff.setEditable(i,false); 
        end

        rowHeader = javax.swing.JList(listModel);
        scrollPane = table_Zcoeff.getTableScrollPane;
        scrollPane.setRowHeaderView(rowHeader);

        rowHeader.setBackground(java.awt.Color.lightGray);
        rowHeader.setFixedCellHeight(jtable_Zcoeff.getRowHeight);
        rowHeader.setFixedCellWidth(66);
    case 2015
        table_Zcoeff = createTable(tab3,{'All','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'},...
            {'0', '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0'},...
            'Buttons',false,'Visible',false,...
            'AutoResizeMode',javax.swing.JTable.AUTO_RESIZE_OFF,... % Do not adjust column widths automatically; use a scrollbar.
            'Units','pix','Position',[5,tabgrp_h-table_h2-29,panel_fw-5,table_h2],...
            'Editable',true,'DataChangedCallback',@table_Zcoeff_DataChangedCallback,...
            'ColumnWidth',29);
        jtable_Zcoeff = table_Zcoeff.getTable;
        jtable_Zcoeff.setRowHeight(17);
        renderer = javax.swing.table.DefaultTableCellRenderer;
        renderer.setForeground(java.awt.Color.lightGray);
        renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        for i = 0:20 % java indexing
            jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
            table_Zcoeff.setEditable(i,false); 
        end

        rowHeader = javax.swing.JList(listModel);
        scrollPane = table_Zcoeff.getTableScrollPane;
        scrollPane.setRowHeaderView(rowHeader);

        rowHeader.setBackground(java.awt.Color.lightGray);
        rowHeader.setFixedCellHeight(jtable_Zcoeff.getRowHeight);
        rowHeader.setFixedCellWidth(64);
    case 2010
        table_Zcoeff = createTable(tab3,{'All','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'},...
            {'0', '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0'},...
            'Buttons',false,'Visible',false,...
            'AutoResizeMode',javax.swing.JTable.AUTO_RESIZE_OFF,... % Do not adjust column widths automatically; use a scrollbar.
            'Units','pix','Position',[5,tabgrp_h-table_h2-40,panel_fw+4,table_h2-5],...
            'Editable',true,'DataChangedCallback',@table_Zcoeff_DataChangedCallback);
        jtable_Zcoeff = table_Zcoeff.getTable;
        jtable_Zcoeff.setRowHeight(17);
        renderer = javax.swing.table.DefaultTableCellRenderer;
        renderer.setForeground(java.awt.Color.lightGray);
        renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        for i = 0:20 % java indexing
            jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
            table_Zcoeff.setEditable(i,false); 
        end

        rowHeader = javax.swing.JList(listModel);
        scrollPane = table_Zcoeff.getTableScrollPane;
        scrollPane.setRowHeaderView(rowHeader);

        rowHeader.setBackground(java.awt.Color.lightGray);
        rowHeader.setFixedCellHeight(jtable_Zcoeff.getRowHeight);
        rowHeader.setFixedCellWidth(65);
    case 2007 %tested with Matlab version 2007b
        table_Zcoeff = createTable(tab3,{'All','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'},...
            {'0', '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0';...
            '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '0'},...
            'Buttons',false,'Visible',false,...
            'AutoResizeMode',javax.swing.JTable.AUTO_RESIZE_OFF,... % Do not adjust column widths automatically; use a scrollbar.
            'Units','pix','Position',[5,tabgrp_h-table_h2-40,panel_fw+4,table_h2-5],...
            'Editable',true,'DataChangedCallback',@table_Zcoeff_DataChangedCallback);
        jtable_Zcoeff = table_Zcoeff.getTable;
        %jtable_Zcoeff.setRowHeight(16);
        renderer = javax.swing.table.DefaultTableCellRenderer;
        renderer.setForeground(java.awt.Color.lightGray);
        renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        for i = 0:20 % java indexing
            jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
            table_Zcoeff.setEditable(i,false); 
        end

        rowHeader = javax.swing.JList(listModel);
        scrollPane = table_Zcoeff.getTableScrollPane;
        scrollPane.setRowHeaderView(rowHeader);

        rowHeader.setBackground(java.awt.Color.lightGray);
        rowHeader.setFixedCellHeight(jtable_Zcoeff.getRowHeight);
        rowHeader.setFixedCellWidth(65);
end

pbutton_saveCorr = uicontrol('Parent',tab3,'String','SAVE','Units','pixels',...
    'Position',[15 60 55 20],'Callback',@pbutton_saveCorr_press,...
    'Fontsize',8,'Enable','on');
pbutton_resetActiveCorr = uicontrol('Parent',tab3,'String','Reset active','Units','pixels',...
    'Position',[72.5 60 70 20],'Callback',@pbutton_resetActiveCorr_press,...
    'Fontsize',8);
pbutton_resetAllCorr = uicontrol('Parent',tab3,'String','Reset all','Units','pixels',...
    'Position',[145 60 60 20],'Callback',@pbutton_resetAllCorr_press,...
    'Fontsize',8);

if MatlabVer == 2016
    set(pbutton_saveCorr,'Position',[15 45 55 20]);
    set(pbutton_resetActiveCorr,'Position',[72.5 45 70 20]);
    set(pbutton_resetAllCorr,'Position',[145 45 60 20]);
end

    
% TAB 4: SETTINGS (Mode, Screen number, Wavelength)

popup_mode = uicontrol('Parent',tab4,'Style','Popup','String',{'Experiment','Debug'},...
    'Callback',@popup_mode_select,'Fontsize',8);                
label_popup_mode = uicontrol('Parent',tab4,'Style','Text','String','Mode:',...
    'HorizontalAlignment','left','Enable','on','Fontsize',8);
popup_screenN = uicontrol('Parent',tab4,'Style','Popup','String',{'2','3'},...
    'Callback',@popup_screenN_select,'Fontsize',8);
label_popup_screenN = uicontrol('Parent',tab4,'Style','Text','String','SLM display:',...
    'HorizontalAlignment','left','Enable','on','Position',[15, tabgrp_h-68, 80, 20],...
    'Fontsize',8);    
edit_lambda = uicontrol('Parent',tab4,'style','edit','unit','pix',...
    'string','750','Enable','on','BackgroundColor',[1 1 1],...
    'Callback',@edit_lambda_Callback,'Fontsize',8);  
uicontrol('Parent',tab4,'Style','Text','String','Wavelength (nm):',...
    'Position',[15, tabgrp_h-92, 87, 20],'HorizontalAlignment','left','Enable','on',...
    'Fontsize',8);
popup_objective = uicontrol('Parent',tab4,'Style','Popup','String',{'Nikon 60x','Zeiss 20x'},...
    'Value',1,'Position',[75, tabgrp_h-116, 95, 20],'Callback',@popup_objective_select,...
    'Fontsize',8,'Enable','on');                
uicontrol('Parent',tab4,'Style','Text','String','Objective:',...
    'HorizontalAlignment','left','Enable','on','Fontsize',8,...
    'Position',[15, tabgrp_h-116, 50, 20]);
% Find out if MES is running. If yes, set Mode to Experiment. Otherwise,
% set Mode to Debug.
try
    mth = bgmanage_image('getnearest');
    set(popup_mode,'Value',1);
    set(popup_screenN,'Enable','on');
catch
    set(popup_mode,'Value',2);
    set(popup_screenN,'Enable','off');
end


% Push button for starting hologram projection
pbutton_startHolo = uicontrol('Parent',tab4,'String','Start hologram',...
    'Units','pixels','Position',[50 tabgrp_h-190 120 25],...
    'Enable','on','Callback',@pbutton_startHolo_press,'Fontsize',8);

    % Version-specific properties    
    if MatlabVer == 2015 % Tested with R2015a
        set(popup_mode,'Position',[65 tabgrp_h-35 105 20]);
        set(label_popup_mode,'Position',[15, tabgrp_h-40, 35, 20]);
        set(popup_screenN,'Position', [125 tabgrp_h-60 45 20]);
        set(edit_lambda,'Position',[125 tabgrp_h-86 45 20]);
    elseif MatlabVer == 2010 % Tested with R2010a
        set(popup_mode,'Position',[65 tabgrp_h-35 105 20]);
        set(label_popup_mode,'Position',[15, tabgrp_h-40, 30, 20]);
        set(popup_screenN,'Position', [115 tabgrp_h-60 55 20]);
        set(edit_lambda,'Position',[120 tabgrp_h-86 45 20]);
    else % Tested with R2007
        set(popup_mode,'Position',[60 tabgrp_h-35 80 20]);
        set(label_popup_mode,'Position',[15, tabgrp_h-40, 30, 20]);
        set(popup_screenN,'Position', [105 tabgrp_h-60 35 20]);
        set(edit_lambda,'Position',[104 tabgrp_h-86 35 20]);
    end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            INITIALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
loadCalibCorrFile;
try
    C = load('Zern_phase.mat');
    Zern_phase = C.Zern_phase;
catch
    % If Zpoly.mat file is missing, recalculate Zernike polynomials
    Zern_phase = calc_ZernPhase(); 
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          CALLBACK FUNCTIONS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FIGURE

function loadCalibCorrFile(varargin)
    myfile = 'SLM_CalibCorr.mat';
    A = exist(myfile,'file');
    if A == 2 % file exists
        C = load(myfile);
        try
            Xscale_20x = C.Xscale_20x;
            Xscale_60x = C.Xscale_60x;
        catch
            Xscale_20x = 1;
            Xscale_60x = 1;
        end
           
        try
            Yscale_20x = C.Yscale_20x;
            Yscale_60x = C.Yscale_60x;
        catch
            Yscale_20x = 1;
            Yscale_60x = 1;
        end
        
        try
            Zscale_20x = C.Zscale_20x;
            Zscale_60x = C.Zscale_60x;
        catch
            Zscale_20x = 1;
            Zscale_60x = 1;
        end
           
        try
            RotAngle_20x = C.RotAngle_20x;
            RotAngle_60x = C.RotAngle_60x;
        catch
            RotAngle_20x = 0;
            RotAngle_60x = 0;
        end
        
        try
            xyShift_20x = C.xyShift_20x;
            xyShift_60x = C.xyShift_60x;
        catch
            xyShift_20x = {false,'5','0','0';false,'-5','0','0'};
            xyShift_60x = {false,'5','0','0';false,'-5','0','0'};
        end
           
        try
            Zcoeff_20x = C.Zcoeff_20x;
            Zcoeff_60x = C.Zcoeff_60x;
        catch
            Zcoeff_20x = zeros(11,1);
            Zcoeff_60x = zeros(11,1);
        end
        
        try
            xAmpWeight_20x = C.xAmpWeight_20x;
            yAmpWeight1_20x = C.yAmpWeight1_20x;
            yAmpWeight2_20x = C.yAmpWeight2_20x;
            zAmpWeight_20x = C.zAmpWeight_20x;
            xAmpWeight_60x = C.xAmpWeight_60x;
            yAmpWeight1_60x = C.yAmpWeight1_60x;
            yAmpWeight2_60x = C.yAmpWeight2_60x;
            zAmpWeight_60x = C.zAmpWeight_60x;
        catch
            xAmpWeight_20x = 0;
            yAmpWeight1_20x = 0;
            yAmpWeight2_20x = 0;
            zAmpWeight_20x = 0;
            xAmpWeight_60x = 0;
            yAmpWeight1_60x = 0;
            yAmpWeight2_60x = 0;
            zAmpWeight_60x = 0;
        end
        
    else
        Xscale_20x = 1;
        Xscale_60x = 1;
        
        Yscale_20x = 1;
        Yscale_60x = 1;
        
        Zscale_20x = 1;
        Zscale_60x = 1;
        
        RotAngle_20x = 0;
        RotAngle_60x = 0;
        
        xyShift_20x = {false,'5','0','0';false,'-5','0','0'};
        xyShift_60x = {false,'5','0','0';false,'-5','0','0'};
        
        Zcoeff_20x = zeros(11,1);
        Zcoeff_60x = zeros(11,1);
        
        xAmpWeight_20x = 0;
        yAmpWeight1_20x = 0;
        yAmpWeight2_20x = 0;
        zAmpWeight_20x = 0;
        xAmpWeight_60x = 0;
        yAmpWeight1_60x = 0;
        yAmpWeight2_60x = 0;
        zAmpWeight_60x = 0;
    end
    
    if get(popup_objective,'Value') == 1 % 60x
        set(spinner_Xscale,'String',num2str(Xscale_60x)); set(spinner_Xscale,'Value',Xscale_60x);
        set(spinner_Yscale,'String',num2str(Yscale_60x)); set(spinner_Yscale,'Value',Yscale_60x);
        set(spinner_Zscale,'String',num2str(Zscale_60x)); set(spinner_Zscale,'Value',Zscale_60x);
        set(spinner_angle,'String',num2str(RotAngle_60x)); set(spinner_angle,'Value',RotAngle_60x);
        set(table_xyShift,'Data',xyShift_60x);
        for i=1:11 % Java indexing
            jtable_Zcoeff.setValueAt(num2str(Zcoeff_60x(i)), i-1, 0);
        end
        set(check_xAmpWeight,'Value',xAmpWeight_60x);
        set(check_yAmpWeight1,'Value',yAmpWeight1_60x);
        set(check_yAmpWeight2,'Value',yAmpWeight2_60x);
        set(check_zAmpWeight,'Value',zAmpWeight_60x);

    else % 20x
        set(spinner_Xscale,'String',num2str(Xscale_20x)); set(spinner_Xscale,'Value',Xscale_20x);
        set(spinner_Yscale,'String',num2str(Yscale_20x)); set(spinner_Yscale,'Value',Yscale_20x);
        set(spinner_Zscale,'String',num2str(Zscale_20x)); set(spinner_Zscale,'Value',Zscale_20x);
        set(spinner_angle,'String',num2str(RotAngle_20x)); set(spinner_angle,'Value',RotAngle_20x);
        set(table_xyShift,'Data',xyShift_20x);
        for i=1:11 % Java indexing
            jtable_Zcoeff.setValueAt(num2str(Zcoeff_20x(i)), i-1, 0);
        end
        set(check_xAmpWeight,'Value',xAmpWeight_20x);
        set(check_yAmpWeight1,'Value',yAmpWeight1_20x);
        set(check_yAmpWeight2,'Value',yAmpWeight2_20x);
        set(check_zAmpWeight,'Value',zAmpWeight_20x);
    end
    
    setappdata(hfig,'Xscale_20x',Xscale_20x);
    setappdata(hfig,'Xscale_60x',Xscale_60x);
    
    setappdata(hfig,'Yscale_20x',Yscale_20x);
    setappdata(hfig,'Yscale_60x',Yscale_60x);
    
    setappdata(hfig,'Zscale_20x',Zscale_20x);
    setappdata(hfig,'Zscale_60x',Zscale_60x);
    
    setappdata(hfig,'RotAngle_20x',RotAngle_20x);
    setappdata(hfig,'RotAngle_60x',RotAngle_60x);
    
    setappdata(hfig,'Zcoeff_20x',Zcoeff_20x);
    setappdata(hfig,'Zcoeff_60x',Zcoeff_60x);

    setappdata(hfig,'xyShift_20x',xyShift_20x);
    setappdata(hfig,'xyShift_60x',xyShift_60x);
    
    setappdata(hfig,'xAmpWeight_20x',xAmpWeight_20x);
    setappdata(hfig,'yAmpWeight1_20x',yAmpWeight1_20x);
    setappdata(hfig,'yAmpWeight2_20x',yAmpWeight2_20x);
    setappdata(hfig,'zAmpWeight_20x',zAmpWeight_20x);
    setappdata(hfig,'xAmpWeight_60x',xAmpWeight_60x);
    setappdata(hfig,'yAmpWeight1_60x',yAmpWeight1_60x);
    setappdata(hfig,'yAmpWeight2_60x',yAmpWeight2_60x);
    setappdata(hfig,'zAmpWeight_60x',zAmpWeight_60x);
end

function tab_select_change(varargin)
    if MatlabVer >= 2015  
        index = get(htabgroup,'SelectedTab');
        switch index
            case tab4 
                table_coords.setVisible(false);
                table_xyShift.setVisible(false);
                table_Zcoeff.setVisible(false);
                set(pbutton_updateHolo,'Visible','off');
                set(toggle_contHolo,'Visible','off');
                set(pbutton_blankHolo,'Visible','off');
                set(pbutton_updateImage,'Visible','off');
                set(popup_mode,'Visible','on');
                set(popup_screenN,'Visible','on');
            case tab1
                table_coords.setVisible(true);
                table_xyShift.setVisible(false);
                table_Zcoeff.setVisible(false);
                set(pbutton_updateHolo,'Visible','on');
                set(toggle_contHolo,'Visible','on');
                set(pbutton_blankHolo,'Visible','on');
                set(pbutton_updateImage,'Visible','on');
                set(popup_mode,'Visible','off');
                set(popup_screenN,'Visible','off');
            case tab2
                table_coords.setVisible(false);
                table_xyShift.setVisible(true);
                table_Zcoeff.setVisible(false);
                set(pbutton_updateHolo,'Visible','on');
                set(toggle_contHolo,'Visible','on');
                set(pbutton_blankHolo,'Visible','on');
                set(pbutton_updateImage,'Visible','on');
                set(popup_mode,'Visible','off');
                set(popup_screenN,'Visible','off');
            case tab3
                table_coords.setVisible(false);
                table_xyShift.setVisible(false);
                table_Zcoeff.setVisible(true);
                set(pbutton_updateHolo,'Visible','on');
                set(toggle_contHolo,'Visible','on');
                set(pbutton_blankHolo,'Visible','on');
                set(pbutton_updateImage,'Visible','on');
                set(popup_mode,'Visible','off');
                set(popup_screenN,'Visible','off');
        end
    else % R2007 and R2010
        index = get(htabgroup,'SelectedIndex');
        switch index
            case 4 
                table_coords.setVisible(false);
                table_xyShift.setVisible(false);
                table_Zcoeff.setVisible(false);
                set(pbutton_updateHolo,'Visible','off');
                set(toggle_contHolo,'Visible','off');
                set(pbutton_blankHolo,'Visible','off');
                set(pbutton_updateImage,'Visible','off');
                set(popup_mode,'Visible','on');
                set(popup_screenN,'Visible','on');
            case 1
                table_coords.setVisible(true);
                table_xyShift.setVisible(false);
                table_Zcoeff.setVisible(false);
                set(pbutton_updateHolo,'Visible','on');
                set(toggle_contHolo,'Visible','on');
                set(pbutton_blankHolo,'Visible','on');
                set(pbutton_updateImage,'Visible','on');
                set(popup_mode,'Visible','off');
                set(popup_screenN,'Visible','off');
            case 2
                table_coords.setVisible(false);
                table_xyShift.setVisible(true);
                table_Zcoeff.setVisible(false);
                set(pbutton_updateHolo,'Visible','on');
                set(toggle_contHolo,'Visible','on');
                set(pbutton_blankHolo,'Visible','on');
                set(pbutton_updateImage,'Visible','on');
                set(popup_mode,'Visible','off');
                set(popup_screenN,'Visible','off');
            case 3
                table_coords.setVisible(false);
                table_xyShift.setVisible(false);
                table_Zcoeff.setVisible(true);
                set(pbutton_updateHolo,'Visible','on');
                set(toggle_contHolo,'Visible','on');
                set(pbutton_blankHolo,'Visible','on');
                set(pbutton_updateImage,'Visible','on');
                set(popup_mode,'Visible','off');
                set(popup_screenN,'Visible','off');
        end
    end
end

function pbutton_updateHolo_press(varargin)
    hX = getappdata(hfig,'hX');
    hY = getappdata(hfig,'hY');
    hZ = getappdata(hfig,'hZ');
    L = getappdata(hfig,'L');

    if isempty(hX)
        update_holo(400,400,0,0);
    else
        update_holo(hX,hY,hZ,L);
    end
end

function contHolo_toggle(varargin)
    if get(toggle_contHolo,'Value') == 1
        set(pbutton_updateHolo,'Enable','off');
        set(pbutton_updateHolo,'ForegroundColor',[0.5 0.5 0.5]);
        set(toggle_contHolo,'ForegroundColor',[0 0 1]);

        rowCount = jtable_coords.getRowCount;
        if rowCount ~= 0
            try
                hX = getappdata(hfig,'hX');
                hY = getappdata(hfig,'hY');
                hZ = getappdata(hfig,'hZ');
                L = getappdata(hfig,'L');
                update_holo(hX,hY,hZ,L);
            catch
                [sX,sY,Aind,sZ,L] = get_ActivesXYZL(table_coords);
                [hX,hY,hZ] = calc_hXYZ(sX,sY,sZ);
                update_holo(hX,hY,hZ,L);
            end
        end
    elseif get(toggle_contHolo,'Value') == 0
        set(pbutton_updateHolo,'Enable','on');
        set(pbutton_updateHolo,'ForegroundColor',[0 0 0]);
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);
    end
end

function pbutton_blankHolo_press(varargin)
    data = cell(table_coords.getData);
    if not(isempty(data))
        A = cell2mat(data(:,1));
        k = find(A==1);
        for i=1:size(k,1)
            % Uncheck all checkboxes
            jtable_coords.setValueAt(false, k(i)-1, 0);
        end
    end
    update_holo(400,400,0,0);
    setappdata(hfig,'hX',400);
    setappdata(hfig,'hY',400);
    setappdata(hfig,'hZ',0);
    setappdata(hfig,'L',0);
end

function pbutton_updateImage_press(varargin)
    modeID = get(popup_mode,'Value');
    if modeID == 1 % Experiment mode
        try
            mth = bgmanage_image('getnearest');
        catch
            beep;
            errordlg(error_MESnotrunning);
            return
        end

        widthstep_new = get(mth,1,'WidthStep'); % The current MES widthstep
        widthstep_old = getappdata(hfig,'widthstep');
        if ~isempty(widthstep_old)
            widthstep_diff = abs(widthstep_new - widthstep_old);
            if widthstep_diff ~= 0
                % Scale spot coordinates 
                widthstep_ratio = widthstep_new/widthstep_old;
                [sX,sY] = get_allsXYZL(table_coords); % These are centered.
                sX_scaled = sX/widthstep_ratio;
                sY_scaled = sY/widthstep_ratio;
                for i = 1:size(sX)
                    jtable_coords.setValueAt(num2str(sX_scaled(i)), i-1, 1); % Java indexing
                    jtable_coords.setValueAt(num2str(sY_scaled(i)), i-1, 2); % Java indexing
                end
                setappdata(hfig,'widthstep',widthstep_new);
            end
        else % No widthstep has yet been saved
            setappdata(hfig,'widthstep',widthstep_new);
        end
    end
    
    drawSpotsonImage;
    set(toggle_measureDist,'Value',0);
    set(toggle_measureDist,'ForegroundColor',[0 0 0]);
end


% TAB 1

function spinner_Nspots_inc_Callback(varargin)
    Nspots = get(spinner_Nspots,'Value');
    Nspots = Nspots + 1;
    if Nspots > Nmax
        Nspots = Nmax;
    end
    set(spinner_Nspots,'String',num2str(Nspots)); set(spinner_Nspots,'Value',Nspots);

    rowCount = jtable_coords.getRowCount;
      % Add a row if row count < Nmax
      if (rowCount < Nmax)  % might be==0 during slow processing & user double-click
          newRowData = {true,'0','0','0','0'};
          table_coords.getTableModel.addRow(newRowData);
          jtable_coords.changeSelection(jtable_coords.getRowCount-1,0,false,false);
          set(pbutton_addSpot,'Enable','on');
          set(pbutton_delSpot,'Enable','on');
          set(pbutton_activateAllSpots,'Enable','on');
          set(pbutton_saveSpots,'Enable','on');
          renderer = javax.swing.table.DefaultTableCellRenderer;
          renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
          jtable_coords.getColumnModel.getColumn(3).setCellRenderer(renderer);
          jtable_coords.getColumnModel.getColumn(4).setCellRenderer(renderer);
          checkCursorCtrl();
      end
      % Disable further adding of rows if row count >= Nmax
      if (jtable_coords.getRowCount >= Nmax)
          set(pbutton_addSpot,'Enable','off');
      end
end

function spinner_Nspots_dec_Callback(varargin)
    Nspots = get(spinner_Nspots,'Value');
    Nspots = Nspots - 1;
    if Nspots < Nmin
        Nspots = Nmin;
    end
    set(spinner_Nspots,'String',num2str(Nspots)); set(spinner_Nspots,'Value',Nspots);
    
    rowCount = jtable_coords.getRowCount;
      % Delete last row if row count > 0
      if (rowCount > 0)  % might be==0 during slow processing & user double-click
          currentRow = max(0,jtable_coords.getSelectedRow);
          currentCol = max(0,jtable_coords.getSelectedColumn);
          table_coords.getTableModel.removeRow(currentRow);
          if currentRow >= rowCount-1
              jtable_coords.changeSelection(currentRow-1, currentCol, false, false);
          elseif jtable_coords.getSelectedRow < 0
              jtable_coords.changeSelection(currentRow, currentCol, false, false);
          end
          set(pbutton_addSpot,'Enable','on');
          set(pbutton_delSpot,'Enable','on');
          checkCursorCtrl();
      end
      % Disable further deletion if row count <= 0
      if (jtable_coords.getRowCount <= 0)
          set(pbutton_addSpot,'Enable','on');
          set(pbutton_delSpot,'Enable','off');
          set(pbutton_activateAllSpots,'Enable','off');
          set(pbutton_saveSpots,'Enable','off');
      end
end

function table_coords_DataChangedCallback(varargin)
    % Adjust appearance and editability of table_coords depending on value
    % of check_cursorCtr
    checkCursorCtrl();
    % Check that all table_coords entries are numeric
    get_allsXYZL(table_coords);
    % Retrieve XYZL values of active sites for updating of hologram
    [sX,sY,Aind,sZ,L] = get_ActivesXYZL(table_coords);
    updateHoloCont = get(toggle_contHolo,'Value');
    
    % Update hologram continuously if Continuous holo is ON. Otherwise,
    % save hX,hY,hZ for future instances of update_holo
    if isempty(Aind) % No active sites
        hX = 0; hY = 0; hZ = 0; L = 0;
        if updateHoloCont == 1 % Continuous holo is ON
            update_holo(hX,hY,hZ,L);
        end
        
        % Disable calibration editing
        set(edit_stepXYZ,'Enable','off');
        set(edit_stepA,'Enable','off');
        set(table_xyShift,'Editable',false);
        renderer = javax.swing.table.DefaultTableCellRenderer;
            renderer.setForeground(java.awt.Color.lightGray);
            renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
            for i = 1:3
                jtable_xyShift.getColumnModel.getColumn(i).setCellRenderer(renderer);
            end
        set(check_xAmpWeight,'Enable','off');
        set(check_yAmpWeight,'Enable','off');
        set(check_zAmpWeight,'Enable','off');

        % Disable correction editing     
        renderer = javax.swing.table.DefaultTableCellRenderer;
            renderer.setForeground(java.awt.Color.lightGray);
            renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
            for i = 0:20 % java indexing
                jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer); 
                table_Zcoeff.setEditable(i+1,false); % Matlab indexing
            end
            
    else % There is at least 1 active site
        [hX,hY,hZ] = calc_hXYZ(sX,sY,sZ);
        if updateHoloCont == 1 % Continuous holo is ON
            update_holo(hX,hY,hZ,L);
        end
        
        % Enable calibration editing
        set(edit_stepXYZ,'Enable','on');
        set(edit_stepA,'Enable','on');
        set(table_xyShift,'Editable',true);
        renderer = javax.swing.table.DefaultTableCellRenderer;
            renderer.setForeground(java.awt.Color.black);
            renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
            for i = 1:3
                jtable_xyShift.getColumnModel.getColumn(i).setCellRenderer(renderer);
            end
        % set(check_xAmpWeight,'Enable','on');
        set(check_yAmpWeight1,'Enable','on');
        set(check_yAmpWeight2,'Enable','on');
        set(check_zAmpWeight,'Enable','on');

        % Enable correction editing
        if get(check_uniformCorr,'Value') == 1
            % If box is checked, only first column appears black and is editable.
            % The rest of the columns are light gray and uneditable.
                  
            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.lightGray);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                for i = 0:20 % java indexing
                    jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer); 
                    table_Zcoeff.setEditable(i+1,false); % Matlab indexing  
                end

            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.black);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                jtable_Zcoeff.getColumnModel.getColumn(0).setCellRenderer(renderer); 
                table_Zcoeff.setEditable(1,true); % Matlab indexing

            jtable_Zcoeff.repaint;

        else % If box is unchecked, only columns for active sites appear black. The rest 
             % are light gray. 'All' column in uneditable.

            renderer = javax.swing.table.DefaultTableCellRenderer;
            renderer.setForeground(java.awt.Color.lightGray);
            renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
            for i = 0:20 % java indexing
                jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
                table_Zcoeff.setEditable(i+1,false); % Matlab indexing
            end

        renderer = javax.swing.table.DefaultTableCellRenderer;
            renderer.setForeground(java.awt.Color.black);
            renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
            [sX,sY,Aind] = get_ActivesXYZL(table_coords);
            for i = 1:numel(Aind)
                k = Aind(i);
                jtable_Zcoeff.getColumnModel.getColumn(k).setCellRenderer(renderer);
            end
            
            Nspots = get(spinner_Nspots,'Value');
            for i = 1:Nspots
                table_Zcoeff.setEditable(i+1,true); % matlab indexing
            end
            
            jtable_Zcoeff.repaint;
        end
    end
    setappdata(hfig,'hX',hX);
    setappdata(hfig,'hY',hY);
    setappdata(hfig,'hZ',hZ);
    setappdata(hfig,'L',L);
   
    % Update cross hairs if cursor control is OFF
    k = get(check_cursorCtrl,'Value');
    if k == 0
        rowCount = jtable_coords.getRowCount;
        if rowCount ~= 0
            update_crossHairs(sX,sY,Aind);
        end
    end
end

function check_cursorCtrl_Callback(varargin)
    % Change appearance and editability of table if checkbox is checked
    checkCursorCtrl();
    
    k = get(check_cursorCtrl,'Value');
    if k == 1 % Cursor contrl is ON
        % Warn user that Continuous holo and table editing of x and y are
        % now disabled
        % set(text_warn,'Visible','on');
        
        % Disable Continuous holo. This greatly slows down Matlab.
        set(toggle_contHolo,'Value',0);
        set(toggle_contHolo,'Enable','off');
        set(toggle_contHolo,'ForegroundColor',[0.5 0.5 0.5]);
        set(pbutton_updateHolo,'Enable','on');
        set(pbutton_updateHolo,'ForegroundColor',[0 0 0]);
    
    else % Cursor control is OFF
        set(text_warn,'Visible','off');
        set(toggle_contHolo,'Enable','on');
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);
    end
    
    drawSpotsonImage;
end

function cursorPosChange(pos,n)
    x = pos(1);
    y = pos(2);
    modeID = get(popup_mode,'Value');
    if modeID == 1 % Experiment
        try
            mth = bgmanage_image('getnearest');
        catch
            beep;
            errordlg(error_MESnotrunning);
            return
        end
        try
            image = get(mth,1,'IMAGE');
            imageDim = size(image);
            
            [X,Y] = centerOrigin(x,y,imageDim);
            jtable_coords.setValueAt(num2str(X), n-1, 1);
            jtable_coords.setValueAt(num2str(Y), n-1, 2);
        catch
            beep;
            errordlg(error_no2Pimage);
            return
        end
    else % Debug
        try
            image = imread(sample_image);
        catch
            image = zeros(800);
        end
        imageDim = size(image);

        [X,Y] = centerOrigin(x,y,imageDim);
        jtable_coords.setValueAt(num2str(X), n-1, 1);
        jtable_coords.setValueAt(num2str(Y), n-1, 2);
    end
end

function pbutton_addSpot_press(varargin)
    % Stop any current editing
    component = jtable_coords.getEditorComponent;
    if ~isempty(component)
        event = javax.swing.event.ChangeEvent(component);
        jtable_coords.editingStopped(event);
    end
          
    % If the max number of rows has not been reached,
    % Add a new row at the bottom of the data table
    rowCount = jtable_coords.getRowCount;
    if (rowCount < Nmax)  % might be==0 during slow processing & user double-click
        set(spinner_Nspots,'String',num2str(rowCount+1)); set(spinner_Nspots,'Value',rowCount+1);
        newRowData = {true,'0','0','0','0'};
        table_coords.getTableModel.addRow(newRowData);
        jtable_coords.changeSelection(jtable_coords.getRowCount-1,0,false,false);
        set(pbutton_addSpot,'Enable','on');
        set(pbutton_delSpot,'Enable','on');
        set(pbutton_activateAllSpots,'Enable','on');
        renderer = javax.swing.table.DefaultTableCellRenderer;
        renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        jtable_coords.getColumnModel.getColumn(3).setCellRenderer(renderer);
        jtable_coords.getColumnModel.getColumn(4).setCellRenderer(renderer);
        checkCursorCtrl();
    end
    % Disable further adding of rows if row count >= Nmax
    if (jtable_coords.getRowCount >= Nmax)
        set(pbutton_addSpot,'Enable','off');
    end
    
    check_showLabels_Callback;
end

function pbutton_delSpot_press(varargin)
    % Stop any current editing
    component = jtable_coords.getEditorComponent;
    if ~isempty(component)
        event = javax.swing.event.ChangeEvent(component);
        jtable_coords.editingStopped(event);
    end

    % If there are any rows displayed, then delete the currently-selected row
    rowCount = jtable_coords.getRowCount;
    if (rowCount > 0)  % might be==0 during slow processing & user double-click
        currentRow = max(0,jtable_coords.getSelectedRow);
        currentCol = max(0,jtable_coords.getSelectedColumn);
        table_coords.getTableModel.removeRow(currentRow);
        if currentRow >= rowCount-1
            jtable_coords.changeSelection(currentRow-1, currentCol, false, false);
        elseif jtable_coords.getSelectedRow < 0
            jtable_coords.changeSelection(currentRow, currentCol, false, false);
        end
        set(pbutton_addSpot,'Enable','on');
        set(pbutton_delSpot,'Enable','on');
        set(spinner_Nspots,'String',num2str(rowCount-1)); set(spinner_Nspots,'Value',rowCount-1);
        checkCursorCtrl();
    end
    
    % Disable further deletion if row count <= 0
      if (jtable_coords.getRowCount <= 0)
          set(pbutton_addSpot,'Enable','on');
          set(pbutton_delSpot,'Enable','off');
          set(pbutton_activateAllSpots,'Enable','off');
      end
end

function pbutton_activateAllSpots_press(varargin)
    data = cell(table_coords.getData);
    if isempty(data)
    else
        A = cell2mat(data(:,1));
        k = find(A==0);
        for i=1:size(k,1)
            % Check all checkboxes
            jtable_coords.setValueAt(true, k(i)-1, 0);
        end
    end
end

function pbutton_saveSpots_press(varargin)
    [filename, pathname, ansIndex] = uiputfile('*.mat', 'Save Spot locations as');
    if ansIndex == 1
        spotLocations = cell(table_coords.getData);
        full_fname = strcat(pathname,filename);
        save(full_fname, 'spotLocations');
    end
end

function pbutton_loadSpots_press(varargin)
    [filename, pathname, ansIndex] = uigetfile('*.mat', 'Pick an mat-file');
    try
        myfile = strcat(pathname,filename);
        S = load(myfile);
        spotLocations = S.spotLocations;
        set(table_coords,'Data',spotLocations);
        set(pbutton_activateAllSpots,'Enable','on');
    catch
        errordlg(error_wrongSpotLocationsFile);
    end
end

function check_showLabels_Callback(varargin)    
    modeID = get(popup_mode,'Value');
    rowCount = jtable_coords.getRowCount;
    if rowCount > 0
        [sX,sY,Aind] = get_ActivesXYZL(table_coords);
        % If Cursor control is OFF
        if get(check_cursorCtrl,'Value') == 0
            update_crossHairs(sX,sY,Aind);
        % Cursor control is ON
        else 
            % If show label is unchecked
            if get(check_showLabels,'Value') == 0
                A = findobj('type','figure','name','SLM Uncaging Spots');
                if not(isempty(A))
                    if modeID == 1 % Experiment mode
                        try
                            mth = bgmanage_image('getnearest');
                        catch
                            beep;
                            errordlg(error_MESnotrunning);
                            return
                        end
                        try
                            image = get(mth,1,'IMAGE');
                            imageDim = size(image);
                            figure(A); show2Pimage(image);

                            [pX,pY] = uncenterOrigin(sX,sY,imageDim);
                            for i = 1:size(pX)
                                n = Aind(i);
                                p(i) = impoint(gca,[pX(i),pY(i)]);
                                api(i) = iptgetapi(p(i));
                                api(i).setColor('m');
                                api(i).addNewPositionCallback(@(pos) cursorPosChange(pos,n));
                                fcn = makeConstrainToRectFcn('impoint',get(gca,'XLim'),get(gca,'YLim'));
                                api(i).setPositionConstraintFcn(fcn);
                            end
                        catch
                            beep;
                            errordlg(error_no2Pimage);
                            return
                        end
                    else % Debug mode
                        try
                            image = imread(sample_image);
                        catch
                            image = zeros(800);
                        end
                        imageDim = size(image);
                        figure(A); show2Pimage(image);

                        [pX,pY] = uncenterOrigin(sX,sY,imageDim);
                        for i = 1:size(pX)
                            n = Aind(i);
                            p(i) = impoint(gca,[pX(i),pY(i)]);
                            api(i) = iptgetapi(p(i));
                            api(i).setColor('m');
                            api(i).addNewPositionCallback(@(pos) cursorPosChange(pos,n));
                            fcn = makeConstrainToRectFcn('impoint',get(gca,'XLim'),get(gca,'YLim'));
                            api(i).setPositionConstraintFcn(fcn);
                        end
                    end
                end
            else % If show labels is checked
                if modeID == 1 % Experiment mode
                    try
                        mth = bgmanage_image('getnearest');
                    catch
                        beep;
                        errordlg(error_MESnotrunning);
                        return
                    end
                    try
                        image = get(mth,1,'IMAGE');
                        imageDim = size(image);

                        A = findobj('type','figure','name','SLM Uncaging Spots');
                        if isempty(A)
                            figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                                  'Position',[300,0,600,600],'Resize','on');
                            show2Pimage(image);
                            set(toggle_measureDist,'Value',0);
                            set(toggle_measureDist,'ForegroundColor',[0 0 0]);
                        else
                            figure(A); show2Pimage(image);
                        end

                        [pX,pY] = uncenterOrigin(sX,sY,imageDim);
                        for i = 1:size(pX)
                            n = Aind(i);
                            p(i) = impoint(gca,[pX(i),pY(i)]);
                            api(i) = iptgetapi(p(i));
                            api(i).setColor('m'); 
                            api(i).setString(num2str(n));
                            api(i).addNewPositionCallback(@(pos) cursorPosChange(pos,n));
                            fcn = makeConstrainToRectFcn('impoint',get(gca,'XLim'),get(gca,'YLim'));
                            api(i).setPositionConstraintFcn(fcn);
                        end
                    catch
                        beep;
                        errordlg(error_no2Pimage);
                        return
                    end
                else % Debug mode
                    try
                        image = imread(sample_image);
                    catch
                        image = zeros(800);
                    end
                    imageDim = size(image);

                    A = findobj('type','figure','name','SLM Uncaging Spots');
                    if isempty(A)
                        figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                              'Position',[300,0,600,600],'Resize','on');
                        show2Pimage(image);
                        set(toggle_measureDist,'Value',0);
                        set(toggle_measureDist,'ForegroundColor',[0 0 0]);
                    else
                        figure(A); show2Pimage(image);
                    end

                    [pX,pY] = uncenterOrigin(sX,sY,imageDim);
                    for i = 1:size(pX)
                        n = Aind(i);
                        p(i) = impoint(gca,[pX(i),pY(i)]);
                        api(i) = iptgetapi(p(i));
                        api(i).setColor('m');
                        api(i).setString(num2str(n));
                        api(i).addNewPositionCallback(@(pos) cursorPosChange(pos,n));
                        fcn = makeConstrainToRectFcn('impoint',get(gca,'XLim'),get(gca,'YLim'));
                        api(i).setPositionConstraintFcn(fcn);
                    end
                end
            end
        end
    end
end

function check_showUncagingArea_Callback(varargin)
    drawSpotsonImage;
end

function pbutton_driftCorr_press(varargin)
    A = findobj('type','figure','name','Drift correction');
    if not(isempty(A))
        figure(A); 
    else
        w = hfig_w;
        h = 115;
        adjfig = figure('MenuBar','none','Name','Drift correction','NumberTitle','off','Resize','off',...
            'Position',[1680-2*hfig_w,1050-hfig_h-h,w,h]);
        if MatlabVer == 2007
            movegui(adjfig,[-236 -425]);
        else
            movegui(adjfig,[-0.5 -425]);
        end

        % XY drift
        if MatlabVer == 2016
            uicontrol('Parent',adjfig,'Style','Text','String','XY drift',...
            'Position',[45, h-25, 45, 20],'HorizontalAlignment','left','Enable','on');
        else
            uicontrol('Parent',adjfig,'Style','Text','String','XY drift',...
            'Position',[45, h-25, 45, 20],'HorizontalAlignment','left','Enable','on',...
            'BackgroundColor',[0.8 0.8 0.8]);
        end
        uicontrol(adjfig,'FontName','Blue Highway','String','^','Enable','on','FontWeight','bold',...
            'Units','pixels','Position',[51 h-50 30 30],'Callback',@pbutton_xyUP_press);
        uicontrol(adjfig,'FontName','Blue Highway','String','v','Enable','on','FontWeight','bold',...
            'Units','pixels','Position',[51 h-80 30 30],'Callback',@pbutton_xyDOWN_press);
        uicontrol(adjfig,'FontName','Blue Highway','String','<','Enable','on','FontWeight','bold',...
            'Units','pixels','Position',[20 h-65 30 30],'Callback',@pbutton_xyLEFT_press);
        uicontrol(adjfig,'FontName','Blue Highway','String','>','Enable','on','FontWeight','bold',...
            'Units','pixels','Position',[82 h-65 30 30],'Callback',@pbutton_xyRIGHT_press);

        edit_stepXY = uicontrol('Parent',adjfig,'style','edit','unit','pix',...
            'position',[60 h-105 35 20],'string','1','Enable','on','Fontsize',8,...
            'BackgroundColor',[1 1 1],'Callback',@edit_stepXY_Callback);
        if MatlabVer == 2016
            uicontrol('Parent',adjfig,'Style','Text','String','Step:','Fontsize',8,...
            'Position',[30, h-110, 27, 20],'HorizontalAlignment','left','Enable','on');
        else
            uicontrol('Parent',adjfig,'Style','Text','String','Step:','Fontsize',8,...
            'Position',[30, h-110, 27, 20],'HorizontalAlignment','left','Enable','on',...
            'BackgroundColor',[0.8 0.8 0.8]);
        end
        stepXY = str2double(get(edit_stepXY,'String'));
        setappdata(hfig,'stepXY',stepXY);
            
        % Z drift
        if MatlabVer == 2016
            uicontrol('Parent',adjfig,'Style','Text','String','Z drift',...
            'Position',[150, h-25, 45, 20],'HorizontalAlignment','left','Enable','on');
        else
            uicontrol('Parent',adjfig,'Style','Text','String','Z drift',...
            'Position',[150, h-25, 45, 20],'HorizontalAlignment','left','Enable','on',...
            'BackgroundColor',[0.8 0.8 0.8]);
        end
        uicontrol(adjfig,'FontName','Blue Highway','String','^','Enable','on','FontWeight','bold',...
            'Units','pixels','Position',[151 h-50 30 30],'Callback',@pbutton_zUP_press);
        uicontrol(adjfig,'FontName','Blue Highway','String','v','Enable','on','FontWeight','bold',...
            'Units','pixels','Position',[151 h-80 30 30],'Callback',@pbutton_zDOWN_press);

        edit_stepZ = uicontrol('Parent',adjfig,'style','edit','unit','pix',...
            'position',[160 h-105 35 20],'string','1','Enable','on','Fontsize',8,...
            'BackgroundColor',[1 1 1],'Callback',@edit_stepZ_Callback);
        if MatlabVer == 2016
            uicontrol('Parent',adjfig,'Style','Text','String','Step:','Fontsize',8,...
            'Position',[130, h-110, 27, 20],'HorizontalAlignment','left','Enable','on');
        else
            uicontrol('Parent',adjfig,'Style','Text','String','Step:','Fontsize',8,...
            'Position',[130, h-110, 27, 20],'HorizontalAlignment','left','Enable','on',...
            'BackgroundColor',[0.8 0.8 0.8]);
        end
        stepZ = str2double(get(edit_stepZ,'String'));
        setappdata(hfig,'stepZ',stepZ);
        
    end

    % Drift correction callback functions
    function edit_stepXY_Callback(varargin)
        stepStr = get(edit_stepXY,'String'); 
        if not(all(ismember(stepStr, '0123456789.')))
            beep;
            errordlg(error_nonnumericStep);
            return
        else
            stepXY = str2double(stepStr);
            setappdata(hfig,'stepXY',stepXY);
        end
    end  

    function edit_stepZ_Callback(varargin)
        stepStr = get(edit_stepZ,'String');
        if not(all(ismember(stepStr, '0123456789.')))
            beep;
            errordlg(error_nonnumericStep);
            return
        else 
            stepZ = str2double(stepStr);
            setappdata(hfig,'stepZ',stepZ);
        end
    end  

    function pbutton_xyUP_press(varargin)
        set(check_cursorCtrl,'Value',0);
        checkCursorCtrl();
        set(toggle_contHolo,'Value',0);
        set(toggle_contHolo,'Enable','on');
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);
        [sX,sY] = get_allsXYZL(table_coords); % These are centered.
        stepXY = getappdata(hfig,'stepXY');
        for i =1:size(sX)
            sY(i) = sY(i) + stepXY;
            jtable_coords.setValueAt(num2str(sY(i)), i-1, 2);
        end
    end

    function pbutton_xyDOWN_press(varargin)
        set(check_cursorCtrl,'Value',0);
        checkCursorCtrl();
        set(toggle_contHolo,'Value',0);
        set(toggle_contHolo,'Enable','on');
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);

        
        [sX,sY] = get_allsXYZL(table_coords); % These are centered.
        stepXY = getappdata(hfig,'stepXY');
        for i =1:size(sX)
            sY(i) = sY(i) - stepXY;
            jtable_coords.setValueAt(num2str(sY(i)), i-1, 2);
        end
    end

    function pbutton_xyLEFT_press(varargin)
        set(check_cursorCtrl,'Value',0);
        checkCursorCtrl();
        set(toggle_contHolo,'Value',0);
        set(toggle_contHolo,'Enable','on');
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);

        
        sX = get_allsXYZL(table_coords); % These are centered.
        stepXY = getappdata(hfig,'stepXY');
        for i =1:size(sX)
            sX(i) = sX(i) - stepXY;
            jtable_coords.setValueAt(num2str(sX(i)), i-1, 1);
        end
    end

    function pbutton_xyRIGHT_press(varargin)
        set(check_cursorCtrl,'Value',0);
        checkCursorCtrl();
        set(toggle_contHolo,'Value',0);
        set(toggle_contHolo,'Enable','on');
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);
        
        sX = get_allsXYZL(table_coords); % These are centered.
        stepXY = getappdata(hfig,'stepXY');
        for i =1:size(sX)
            sX(i) = sX(i) + stepXY;
            jtable_coords.setValueAt(num2str(sX(i)), i-1, 1);
        end
    end

    function pbutton_zUP_press(varargin)
        set(check_cursorCtrl,'Value',0);
        checkCursorCtrl();
        set(toggle_contHolo,'Value',0);
        set(toggle_contHolo,'Enable','on');
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);
        
        [sX,sY,sZ] = get_allsXYZL(table_coords); % These are centered.
        stepZ = getappdata(hfig,'stepZ');
        for i =1:size(sZ)
            sZ(i) = sZ(i) + stepZ;
            jtable_coords.setValueAt(num2str(sZ(i)), i-1, 3);
        end
    end

    function pbutton_zDOWN_press(varargin)
        set(check_cursorCtrl,'Value',0);
        checkCursorCtrl();
        set(toggle_contHolo,'Value',0);
        set(toggle_contHolo,'Enable','on');
        set(toggle_contHolo,'ForegroundColor',[0 0 0]);
        
        [sX,sY,sZ] = get_allsXYZL(table_coords); % These are centered.
        stepZ = getappdata(hfig,'stepZ');
        for i =1:size(sZ)
            sZ(i) = sZ(i) - stepZ;
            jtable_coords.setValueAt(num2str(sZ(i)), i-1, 3);
        end
    end
end


% TAB 2

function spinner_Xscale_Callback(varargin)
    try
        [sX,sY,Aind,sZ,L] = get_ActivesXYZL(table_coords);
        [hX,hY,hZ] = calc_hXYZ(sX,sY,sZ);
        setappdata(hfig,'hX',hX);
        setappdata(hfig,'hY',hY);
        setappdata(hfig,'hZ',hZ);
        setappdata(hfig,'L',L);

        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    catch
        beep;
        errordlg(error_noActiveSites);
        return
    end
end

function spinner_Yscale_Callback(varargin)
    try
        [sX,sY,Aind,sZ,L] = get_ActivesXYZL(table_coords);
        [hX,hY,hZ] = calc_hXYZ(sX,sY,sZ);
        setappdata(hfig,'hX',hX);
        setappdata(hfig,'hY',hY);
        setappdata(hfig,'hZ',hZ);
        setappdata(hfig,'L',L);

        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    catch
        beep;
        errordlg(error_noActiveSites);
        return
    end
end

function spinner_Zscale_Callback(varargin)
    try
        [sX,sY,Aind,sZ,L] = get_ActivesXYZL(table_coords);
        [hX,hY,hZ] = calc_hXYZ(sX,sY,sZ);
        setappdata(hfig,'hX',hX);
        setappdata(hfig,'hY',hY);
        setappdata(hfig,'hZ',hZ);
        setappdata(hfig,'L',L);

        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    catch
        beep;
        errordlg(error_noActiveSites);
        return
    end
end

function edit_stepXYZ_Callback(varargin)
    stepStr = get(edit_stepXYZ,'String'); 
    if not(all(ismember(stepStr, '0123456789.')))
        beep;
        errordlg(error_nonnumericStep);
        return
    else
        stepXYZ = str2double(stepStr);
        initvalX = get(spinner_Xscale,'Value');
        initvalY = get(spinner_Yscale,'Value');
        initvalZ = get(spinner_Zscale,'Value');
        delete(spinner_Xscale); delete(spinner_Xscale_ud);
        delete(spinner_Yscale); delete(spinner_Yscale_ud);
        delete(spinner_Zscale); delete(spinner_Zscale_ud);
        [spinner_Xscale,spinner_Xscale_ud] = spinner('Parent',tab2,'Position',[70 tabgrp_h-42 50 20],...
            'Startvalue',initvalX,'Min',0,'Max',10,'Step',stepXYZ,'Callback',@spinner_Xscale_Callback);
            set(spinner_Xscale,'Enable','off');
        [spinner_Yscale,spinner_Yscale_ud] = spinner('Parent',tab2,'Position',[70 tabgrp_h-62 50 20],...
            'Startvalue',initvalY,'Min',0,'Max',10,'Step',stepXYZ,'Callback',@spinner_Yscale_Callback);
            set(spinner_Yscale,'Enable','off');
        [spinner_Zscale,spinner_Zscale_ud] = spinner('Parent',tab2,'Position',[70 tabgrp_h-82 50 20],...
            'Startvalue',initvalZ,'Min',0,'Max',10,'Step',stepXYZ,'Callback',@spinner_Zscale_Callback);
            set(spinner_Zscale,'Enable','off');
    end
end
        
function spinner_angle_Callback(varargin)
    try
        [sX,sY,Aind,sZ,L] = get_ActivesXYZL(table_coords);
        [hX,hY,hZ] = calc_hXYZ(sX,sY,sZ);
        setappdata(hfig,'hX',hX);
        setappdata(hfig,'hY',hY);
        setappdata(hfig,'hZ',hZ);
        setappdata(hfig,'L',L);
        
        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    catch
        beep;
        errordlg(error_noActiveSites);
        return
    end
end

function edit_stepA_Callback(varargin)
    stepStr = get(edit_stepA,'String'); 
    if not(all(ismember(stepStr, '0123456789.')))
        beep;
        errordlg(error_nonnumericStep);
        return
    else
        stepA = str2double(get(edit_stepA,'String'));
        initval = get(spinner_angle,'Value');
        delete(spinner_angle); delete(spinner_angle_ud);
        [spinner_angle,spinner_angle_ud] = spinner('Parent',tab2,'Position',[150 tabgrp_h-75 50 20],...
            'Startvalue',initval,'Min',-90,'Max',90,'Step',stepA,'Callback',@spinner_angle_Callback);
            set(spinner_angle,'Enable','off');
    end
end

function table_xyShift_DataChangedCallback(varargin)
    % Only accept real, numeric entries
    data = cell(table_xyShift.getData);
    m = cellfun(@str2double,data(:,2:4));
    
    % Accept only real, numeric values
    if any(isnan(m))
        beep;
        errordlg(error_nonnumericXYshift);
        return
    end
    if any(~isreal(m))
        beep;
        errordlg(error_nonnumericXYshift);
        return
    end
    
    % Recalculate hologram if there is at least one active site
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    if ~isempty(Aind)
        hX = getappdata(hfig,'hX');
        hY = getappdata(hfig,'hY');
        hZ = getappdata(hfig,'hZ');
        L = getappdata(hfig,'L');

        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    end
end

function check_AmpWeight_Callback(varargin)
    % Recalculate hologram if there is at least one active site
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    if ~isempty(Aind)
        hX = getappdata(hfig,'hX');
        hY = getappdata(hfig,'hY');
        hZ = getappdata(hfig,'hZ');
        L = getappdata(hfig,'L');

        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    end
end

function check_yAmpWeight1_Callback(varargin)
    if get(check_yAmpWeight1,'Value') == 1
        set(check_yAmpWeight2,'Value',0);
    end
    
    % Recalculate hologram if there is at least one active site
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    if ~isempty(Aind)
        hX = getappdata(hfig,'hX');
        hY = getappdata(hfig,'hY');
        hZ = getappdata(hfig,'hZ');
        L = getappdata(hfig,'L');

        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    end
end

function check_yAmpWeight2_Callback(varargin)
    if get(check_yAmpWeight2,'Value') == 1
        set(check_yAmpWeight1,'Value',0);
    end
    
    % Recalculate hologram if there is at least one active site
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    if ~isempty(Aind)
        hX = getappdata(hfig,'hX');
        hY = getappdata(hfig,'hY');
        hZ = getappdata(hfig,'hZ');
        L = getappdata(hfig,'L');

        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    end
end

function pbutton_saveCalib_press(varargin)
    if get(popup_objective,'Value') == 1 % 60x
        Xscale_60x = get(spinner_Xscale,'Value');
        Yscale_60x = get(spinner_Yscale,'Value');
        Zscale_60x = get(spinner_Zscale,'Value');
        RotAngle_60x = get(spinner_angle,'Value');
        xyShift_60x = cell(table_xyShift.getData);
        xAmpWeight_60x = get(check_xAmpWeight,'Value');
        yAmpWeight1_60x = get(check_yAmpWeight1,'Value');
        yAmpWeight2_60x = get(check_yAmpWeight2,'Value');
        zAmpWeight_60x = get(check_zAmpWeight,'Value');

        setappdata(hfig,'Xscale_60x',Xscale_60x);
        setappdata(hfig,'Yscale_60x',Yscale_60x);
        setappdata(hfig,'Zscale_60x',Zscale_60x);
        setappdata(hfig,'RotAngle_60x',RotAngle_60x);
        setappdata(hfig,'xyShift_60x',xyShift_60x);
        setappdata(hfig,'xAmpWeight_60x',xAmpWeight_60x);
        setappdata(hfig,'yAmpWeight1_60x',yAmpWeight1_60x);
        setappdata(hfig,'yAmpWeight2_60x',yAmpWeight2_60x);
        setappdata(hfig,'zAmpWeight_60x',zAmpWeight_60x);
        
        Xscale_20x = getappdata(hfig,'Xscale_20x');
        Yscale_20x = getappdata(hfig,'Yscale_20x');
        Zscale_20x = getappdata(hfig,'Zscale_20x');
        RotAngle_20x = getappdata(hfig,'RotAngle_20x');
        xyShift_20x = getappdata(hfig,'xyShift_20x');
        xAmpWeight_20x = getappdata(hfig,'xAmpWeight_20x');
        yAmpWeight1_20x = getappdata(hfig,'yAmpWeight1_20x');
        yAmpWeight2_20x = getappdata(hfig,'yAmpWeight2_20x');
        zAmpWeight_20x = getappdata(hfig,'zAmpWeight_20x');
    else % 20x
        Xscale_20x = get(spinner_Xscale,'Value');
        Yscale_20x = get(spinner_Yscale,'Value');
        Zscale_20x = get(spinner_Zscale,'Value');
        RotAngle_20x = get(spinner_angle,'Value');
        xyShift_20x = cell(table_xyShift.getData);
        xAmpWeight_20x = get(check_xAmpWeight,'Value');
        yAmpWeight1_20x = get(check_yAmpWeight1,'Value');
        yAmpWeight2_20x = get(check_yAmpWeight2,'Value');
        zAmpWeight_20x = get(check_zAmpWeight,'Value');

        setappdata(hfig,'Xscale_20x',Xscale_20x);
        setappdata(hfig,'Yscale_20x',Yscale_20x);
        setappdata(hfig,'Zscale_20x',Zscale_20x);
        setappdata(hfig,'RotAngle_20x',RotAngle_20x);
        setappdata(hfig,'xyShift_20x',xyShift_20x);
        setappdata(hfig,'xAmpWeight_20x',xAmpWeight_20x);
        setappdata(hfig,'yAmpWeight1_20x',yAmpWeight1_20x);
        setappdata(hfig,'yAmpWeight2_20x',yAmpWeight2_20x);
        setappdata(hfig,'zAmpWeight_20x',zAmpWeight_20x);
        
        Xscale_60x = getappdata(hfig,'Xscale_60x');
        Yscale_60x = getappdata(hfig,'Yscale_60x');
        Zscale_60x = getappdata(hfig,'Zscale_60x');
        RotAngle_60x = getappdata(hfig,'RotAngle_60x');
        xyShift_60x = getappdata(hfig,'xyShift_60x');
        xAmpWeight_60x = getappdata(hfig,'xAmpWeight_60x');
        yAmpWeight1_60x = getappdata(hfig,'yAmpWeight1_60x');
        yAmpWeight2_60x = getappdata(hfig,'yAmpWeight2_60x');
        zAmpWeight_60x = getappdata(hfig,'zAmpWeight_60x');
    end
    
    A = exist('SLM_CalibCorr.mat','file');
    if A == 2
        save SLM_CalibCorr.mat Xscale_20x Yscale_20x Zscale_20x RotAngle_20x...
            xyShift_20x xAmpWeight_20x yAmpWeight1_20x yAmpWeight2_20x zAmpWeight_20x -append;
        save SLM_CalibCorr.mat Xscale_60x Yscale_60x Zscale_60x RotAngle_60x...
            xyShift_60x xAmpWeight_60x yAmpWeight1_60x yAmpWeight2_60x zAmpWeight_60x -append;
    else
        save SLM_CalibCorr.mat Xscale_20x Yscale_20x Zscale_20x RotAngle_20x...
            xyShift_20x xAmpWeight_20x yAmpWeight1_20x yAmpWeight2_20x zAmpWeight_20x;
        save SLM_CalibCorr.mat Xscale_60x Yscale_60x Zscale_60x RotAngle_60x...
            xyShift_60x xAmpWeight_60x yAmpWeight1_60x yAmpWeight2_60x zAmpWeight_60x -append;
    end
end

function measureDist_toggle(varargin)
    A = findobj('type','figure','name','SLM Uncaging Spots');
    if get(toggle_measureDist,'Value') == 1
        set(toggle_measureDist,'ForegroundColor',[0 0 1]);
        if not(isempty(A)) % Image figure is open
            figure(A);
        else
            drawSpotsonImage;
        end
            h = imline(gca,[10 100],[100 100]);
            api = iptgetapi(h);
            api.setColor('g');
            api.addNewPositionCallback(@(pos) displayDist(pos));
            fcn = makeConstrainToRectFcn('imline',get(gca,'XLim'),get(gca,'YLim'));
            api.setPositionConstraintFcn(fcn);
    elseif get(toggle_measureDist,'Value') == 0
        set(toggle_measureDist,'ForegroundColor',[0 0 0]);
        pbutton_updateImage_press;
    end
end

function pbutton_resetCalib_press(varargin)
    set(spinner_Xscale,'String','1'); set(spinner_Xscale,'Value',1);
    set(spinner_Yscale,'String','1'); set(spinner_Yscale,'Value',1);
    set(spinner_Zscale,'String','1'); set(spinner_Zscale,'Value',1);
    set(spinner_angle,'String','0'); set(spinner_angle,'Value',0);
    xyShift = {false,'0','0','0';false,'0','0','0'};
    set(table_xyShift,'Data',xyShift);
    set(check_xAmpWeight,'Value',0);
    set(check_yAmpWeight1,'Value',0);
    set(check_yAmpWeight2,'Value',0);
    set(check_zAmpWeight,'Value',0);
end

function displayDist(pos)
    x1 = pos(1,1); y1 = pos(1,2);
    x2 = pos(2,1); y2 = pos(2,2);
    dist_pix = sqrt((x1-x2)^2+(y1-y2)^2);
    % Get the widthstep
    if get(popup_mode,'Value') == 1 % Experiment mode
        widthstep = get(mth,1,'WidthStep');
    else % Debug mode
        widthstep = 0.1;
    end    
    dist_um = dist_pix*widthstep;
    title(strcat(num2str(dist_pix,4),' pixels;', num2str(dist_um,4),' um'));
end


% TAB 3

function check_disableCorr_Callback(varargin)
    disableCorr = get(check_disableCorr,'Value');
    if disableCorr == 1 % Box is checked
        set(check_uniformCorr,'Enable','off');
        set(pbutton_saveCorr,'Enable','off');
        set(pbutton_resetActiveCorr,'Enable','off');
        set(pbutton_resetAllCorr,'Enable','off');
        renderer = javax.swing.table.DefaultTableCellRenderer;
            renderer.setForeground(java.awt.Color.lightGray);
            renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
            for i = 0:20 % java indexing
                jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
                table_Zcoeff.setEditable(i+1,false); % Matlab indexing
            end
        jtable_Zcoeff.repaint;
        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            hX = getappdata(hfig,'hX');
            hY = getappdata(hfig,'hY');
            hZ = getappdata(hfig,'hZ');
            L = getappdata(hfig,'L');
            update_holo(hX,hY,hZ,L);
        end
    else % Box is unchecked
        set(check_uniformCorr,'Enable','on');
        set(pbutton_resetActiveCorr,'Enable','on');
        set(pbutton_resetAllCorr,'Enable','on');
        check_uniformCorr_Callback();
    end
end

function check_uniformCorr_Callback(varargin)
    OnOff = get(check_uniformCorr,'Value');
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    
    if OnOff == 1 % Box is checked
        % Enable saving of correction coefficients as these are applicable
        % to all sites and thus, will be applicable for every experiment.
        set(pbutton_saveCorr,'Enable','on');
       
        if isempty(Aind) % No active sites
            % All columns are grey but first column is editable.
            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.lightGray);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                for i = 0:20 % java indexing
                    jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer); 
                    table_Zcoeff.setEditable(i+1,false); % Matlab indexing  
                end
                table_Zcoeff.setEditable(0,true); % Matlab indexing
            jtable_Zcoeff.repaint;
        else % There are active sites
            % All but first column are grey. First column is editable.
            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.lightGray);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                for i = 0:20 % java indexing
                    jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer); 
                    table_Zcoeff.setEditable(i+1,false); % Matlab indexing  
                end
            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.black);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                jtable_Zcoeff.getColumnModel.getColumn(0).setCellRenderer(renderer); 
                table_Zcoeff.setEditable(1,true); % Matlab indexing
            jtable_Zcoeff.repaint;
            updateHoloCont = get(toggle_contHolo,'Value');
            if updateHoloCont == 1
                hX = getappdata(hfig,'hX');
                hY = getappdata(hfig,'hY');
                hZ = getappdata(hfig,'hZ');
                L = getappdata(hfig,'L');
                update_holo(hX,hY,hZ,L);
            end
        end
        
    else % Box is unchecked
        % Disable saving of correction coefficients as these will be
        % site-dependent and thus, not applicable for next experiment.
        set(pbutton_saveCorr,'Enable','off');
        
        if isempty(Aind) % No active sites
            % All columns are grey. Inactive columns are editable.
            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.lightGray);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                for i = 0:20 % java indexing
                    jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
                    table_Zcoeff.setEditable(i+1,false); % Matlab indexing
                end
            jtable_Zcoeff.repaint;
            Nspots = get(spinner_Nspots,'Value');
            for i = 1:Nspots
                table_Zcoeff.setEditable(i+1,true); % matlab indexing
            end
        else % There are active sites
            % Active columns are black. Both active and inactive columns
            % are editable.
            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.lightGray);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                for i = 0:20 % java indexing
                    jtable_Zcoeff.getColumnModel.getColumn(i).setCellRenderer(renderer);
                    table_Zcoeff.setEditable(i+1,false); % Matlab indexing
                end
            renderer = javax.swing.table.DefaultTableCellRenderer;
                renderer.setForeground(java.awt.Color.black);
                renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
                for i = 1:numel(Aind)
                    k = Aind(i);
                    jtable_Zcoeff.getColumnModel.getColumn(k).setCellRenderer(renderer);
                end
            Nspots = get(spinner_Nspots,'Value');
            for i = 1:Nspots
                table_Zcoeff.setEditable(i+1,true); % matlab indexing
            end
            jtable_Zcoeff.repaint;
            updateHoloCont = get(toggle_contHolo,'Value');
            if updateHoloCont == 1
                hX = getappdata(hfig,'hX');
                hY = getappdata(hfig,'hY');
                hZ = getappdata(hfig,'hZ');
                L = getappdata(hfig,'L');
                update_holo(hX,hY,hZ,L);
            end
        end
    end
end

function table_Zcoeff_DataChangedCallback(varargin)
    % This function will only ever be called when Aberration correciton is
    % enabled and there is at least one site (active or not).
    % Check if all entries are numeric 
    get_allZcoeff(table_Zcoeff);
    
    % Recalculate hologram if there is at least one active site
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    if ~isempty(Aind)
        hX = getappdata(hfig,'hX');
        hY = getappdata(hfig,'hY');
        hZ = getappdata(hfig,'hZ');
        L = getappdata(hfig,'L');
        
        updateHoloCont = get(toggle_contHolo,'Value');
        if updateHoloCont == 1
            update_holo(hX,hY,hZ,L);
        end
    end
end

function pbutton_saveCorr_press(varargin)
    if get(popup_objective,'Value') == 1 % 60x
        data = cell(table_Zcoeff.getData);
        Zcoeff_60x = cellfun(@str2double,data(:,1));
        setappdata(hfig,'Zcoeff_60x',Zcoeff_60x);
        Zcoeff_20x = getappdata(hfig,'Zcoeff_20x');
    else % 20x
        data = cell(table_Zcoeff.getData);
        Zcoeff_20x = cellfun(@str2double,data(:,1));
        setappdata(hfig,'Zcoeff_20x',Zcoeff_20x);
        Zcoeff_60x = getappdata(hfig,'Zcoeff_60x');
    end
    
    A = exist('SLM_CalibCorr.mat','file');
    if A == 2
        save SLM_CalibCorr.mat Zcoeff_20x Zcoeff_60x -append;
    else
        save SLM_CalibCorr.mat Zcoeff_20x Zcoeff_60x;
    end
end

function pbutton_resetActiveCorr_press(varargin)
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    for i = 1:numel(Aind)
        k = Aind(i);
        for j = 1:11
            jtable_Zcoeff.setValueAt('0', j-1, k);
        end
    end
end

function pbutton_resetAllCorr_press(varargin)
    for i = 1:21
        for j = 1:11
            jtable_Zcoeff.setValueAt('0', j-1, i-1);
        end
    end
end

% TAB 4

function popup_mode_select(varargin)
    set(pbutton_startHolo,'Enable','on');
    modeID = get(popup_mode,'Value');
    if modeID == 1 % If Experiment mode is chosen
        set(popup_screenN,'Enable','on');
        set(label_popup_screenN,'Enable','on');
        try
            mth = bgmanage_image('getnearest');
        catch
            beep;
            errordlg(error_MESnotrunning);
            set(popup_mode,'Value',2);
            return
        end
    else % If Debug mode is chosen, disable choosing of SLM display
        set(popup_screenN,'Enable','off');
        set(label_popup_screenN,'Enable','off');
    end
end

function popup_screenN_select(varargin)
    set(pbutton_startHolo,'Enable','on');
end

function edit_lambda_Callback(varargin)
    set(pbutton_startHolo,'Enable','on');
    lambdastr = get(edit_lambda,'String');
    if not(all(ismember(lambdastr, '0123456789')))
        beep;
        errordlg(error_nonnumericLambda);
        return
    else
        lambda = str2double(lambdastr); 
        if or(lambda > 850, lambda < 750)
            beep;
            errordlg(error_outofrangeLambda);
            return
        end
    end
end

function popup_objective_select(varargin)
    if get(popup_objective,'Value') == 1 % 60x
        Xscale_60x = getappdata(hfig,'Xscale_60x');
        Yscale_60x = getappdata(hfig,'Yscale_60x');
        Zscale_60x = getappdata(hfig,'Zscale_60x');
        RotAngle_60x = getappdata(hfig,'RotAngle_60x');
        xyShift_60x = getappdata(hfig,'xyShift_60x');
        Zcoeff_60x = getappdata(hfig,'Zcoeff_60x');
        
        set(spinner_Xscale,'String',num2str(Xscale_60x)); set(spinner_Xscale,'Value',Xscale_60x);
        set(spinner_Yscale,'String',num2str(Yscale_60x)); set(spinner_Yscale,'Value',Yscale_60x);
        set(spinner_Zscale,'String',num2str(Zscale_60x)); set(spinner_Zscale,'Value',Zscale_60x);
        set(spinner_angle,'String',num2str(RotAngle_60x)); set(spinner_angle,'Value',RotAngle_60x);
        set(table_xyShift,'Data',xyShift_60x);
        for i=1:11 % Java indexing
            jtable_Zcoeff.setValueAt(num2str(Zcoeff_60x(i)), i-1, 0);
        end
        
    else % 20x
        Xscale_20x = getappdata(hfig,'Xscale_20x');
        Yscale_20x = getappdata(hfig,'Yscale_20x');
        Zscale_20x = getappdata(hfig,'Zscale_20x');
        RotAngle_20x = getappdata(hfig,'RotAngle_20x');
        xyShift_20x = getappdata(hfig,'xyShift_20x');
        Zcoeff_20x = getappdata(hfig,'Zcoeff_20x');

        set(spinner_Xscale,'String',num2str(Xscale_20x)); set(spinner_Xscale,'Value',Xscale_20x);
        set(spinner_Yscale,'String',num2str(Yscale_20x)); set(spinner_Yscale,'Value',Yscale_20x);
        set(spinner_Zscale,'String',num2str(Zscale_20x)); set(spinner_Zscale,'Value',Zscale_20x);
        set(spinner_angle,'String',num2str(RotAngle_20x)); set(spinner_angle,'Value',RotAngle_20x);
        set(table_xyShift,'Data',xyShift_20x);
        for i=1:11 % Java indexing
            jtable_Zcoeff.setValueAt(num2str(Zcoeff_20x(i)), i-1, 0);
        end
        
    end
    drawSpotsonImage;
end

function pbutton_startHolo_press(varargin)
    edit_lambda_Callback;
    set(pbutton_startHolo,'Enable','off');
    
    modeID = get(popup_mode,'Value');
    if modeID == 1 % Experiment mode
        try % Open PTB onscreen window
            sca; % Close all potentially open PTB onscreen windows 
            Screen('Preference', 'SkipSyncTests', 1);
            PsychDefaultSetup(2);
            uiN = get(popup_screenN,'Value');
            screenNumber = uiN + 1;
            N = 600;
            [SLMwindow, windowRect] = PsychImaging('OpenWindow', screenNumber, 0);
            dstRects = CenterRectOnPointd([0 0 N N], windowRect(3)/2, windowRect(4)/2);
            setappdata(hfig,'SLMwindow',SLMwindow);
            setappdata(hfig,'dstRects',dstRects);
        catch % SLM display might not be connected
            beep;
            errordlg(error_SLMdisconnect);
            return
        end
    end
    A = findobj('type','figure','name','Duplicate window of hologram');
    if isempty(A) % If phase hologram window is not open, open one
        figure('MenuBar','none','Name','Duplicate window of hologram','NumberTitle','off',...
        'Position',[0,0,300,300],'Resize','on');
    else % If phase hologram window is already open, use it
        figure(A);
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          AUXILIARY FUNCTIONS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = get_allsXYZL(mtable)
    % This function retrieves all XYZL values and verifies that they're
    % valid, i.e. numeric.
    data = cell(mtable.getData);
    if isempty(data) % if there are no rows
        sX = [];
        sY = [];
        sZ = [];
        L = [];
    else
        m = cellfun(@str2double,data(:,2:5));
        % Accept only real, numeric values
        if any(isnan(m))
            beep;
            errordlg(error_nonnumericCoords);
            return
        end
        if any(~isreal(m))
            beep;
            errordlg(error_nonnumericCoords);
            return
        end
        sX = m(:,1);
        sY = m(:,2);
        sZ = m(:,3);
        L = m(:,4);
    end
    varargout{1} = sX;
    varargout{2} = sY;
    varargout{3} = sZ;
    varargout{4} = L;
end

function varargout = get_ActivesXYZL(mtable)
    % This function retrieves XYZL values of active sites.
    data = cell(mtable.getData);
    if isempty(data) % if there are no rows
        sX = [];
        sY = [];
        sZ = [];
        Aind = [];
        L = [];
    else
        A = cell2mat(data(:,1)); 
        activeS = find(A == true);
        Aind = activeS; % Aind contains matlab indices
        if isempty(Aind) % if none of the rows is checked
            sX = [];
            sY = [];
            sZ = [];
            Aind = [];
            L = [];
        else
            X = data(:,2); % matlab indexing
            Y = data(:,3);
            Z = data(:,4);
            LL = data(:,5);
            sX = zeros(size(activeS));
            sY = zeros(size(activeS));
            sZ = zeros(size(activeS));
            L = zeros(size(activeS));
            for i = 1:size(activeS,1)
                sX(i) = str2double(X{activeS(i)}); 
                sY(i) = str2double(Y{activeS(i)}); 
                sZ(i) = str2double(Z{activeS(i)});
                L(i) = str2double(LL{activeS(i)});
            end
        end
    end
    varargout{1} = sX;
    varargout{2} = sY;
    varargout{3} = Aind;
    varargout{4} = sZ;
    varargout{5} = L;
end

function get_allZcoeff(mtable)
    % This function retrieves all Zernike coefficients from Tab 3 and verifies that 
    % they're valid, i.e. numeric. Note: Table_Zcoeff will never be empty.
    
    data = cell(mtable.getData);
    Nspots = get(spinner_Nspots,'Value');
    
    if get(check_uniformCorr,'Value') == 1 % Only 'All' column is relevant
        Zc = cellfun(@str2double,data(:,1));
    else % All columns with spots (active or not) are relevant
        Zc = cellfun(@str2double,data(:,2:Nspots+1));
    end
    
    % Accept only real, numeric values
    if any(isnan(Zc))
        beep;
        errordlg(error_nonnumericZcoeffs);
        return
    end
    if any(~isreal(Zc))
        beep;
        errordlg(error_nonnumericZcoeffs);
        return
    end
end

function Zcoeff = get_ActiveZcoeff(mtable)
    data = cell(mtable.getData);
    [sX,sY,Aind] = get_ActivesXYZL(table_coords);
    Zcoeff = zeros(11,numel(Aind));
    
    if ~isempty(Aind)
        if get(check_uniformCorr,'Value') == 1 % Only 'All' column is relevant
            Zcc = data(:,1);
            for i = 1:11
                Zc(i) = str2double(Zcc{i});
            end
            for i = 1:numel(Aind)
                Zcoeff(:,i) = Zc;
            end
        else
            Zcoeff = cellfun(@str2double,data(:,Aind+1));
        end
    end
end

function update_crossHairs(X,Y,Aind)
    modeID = get(popup_mode,'Value');
    if modeID == 1 % Experiment mode
        try
            mth = bgmanage_image('getnearest');
        catch
            beep;
            errordlg(error_MESnotrunning);
            return
        end
        try
            image = get(mth,1,'IMAGE');
            imageDim = size(image);
            
            A = findobj('type','figure','name','SLM Uncaging Spots');
            if isempty(A)
                figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                      'Position',[300,0,600,600],'Resize','on');
                show2Pimage(image);
                set(toggle_measureDist,'Value',0);
                set(toggle_measureDist,'ForegroundColor',[0 0 0]);
            else
                figure(A); show2Pimage(image);
            end
    
            % Position + symbols at spot coordinates
            [X,Y] = uncenterOrigin(X,Y,imageDim);
            hold on
            plot(X,Y,'r+','MarkerSize',6);
            if get(check_showLabels,'Value') == 1 % Show spot labels is ON
                text(X+15,Y+10,num2str(Aind),'Color',[1,0,0],'BackgroundColor',[1,1,1]);
            end
            hold off
        catch
            beep;
            errordlg(error_no2Pimage);
            return
        end
    else % Debug mode
        try
            image = imread(sample_image);
        catch
            image = zeros(800);
        end
        imageDim = size(image);

        A = findobj('type','figure','name','SLM Uncaging Spots');
        if isempty(A)
            figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                  'Position',[300,0,600,600],'Resize','on');
            show2Pimage(image);
            set(toggle_measureDist,'Value',0);
            set(toggle_measureDist,'ForegroundColor',[0 0 0]);
        else
            figure(A); show2Pimage(image);
        end

        % Position + symbols at spot coordinates
        [X,Y] = uncenterOrigin(X,Y,imageDim);
        hold on
        plot(X,Y,'r+','MarkerSize',6);
        if get(check_showLabels,'Value') == 1 % Show spot labels is ON
            text(X+15,Y+10,num2str(Aind),'Color',[1,0,0],'BackgroundColor',[1,1,1]);
        end

        hold off
    end
end

function update_holo(X,Y,Z,L)
    disp('Please wait...');
    modeID = get(popup_mode,'Value');
    SLMwindow  = getappdata(hfig,'SLMwindow');

    if modeID == 1 % Experiment mode
        try % Obtain widthstep from MES
            mth = bgmanage_image('getnearest');
            widthstep = get(mth,1,'WidthStep');
            d = calc_d();
            X = X*widthstep/d;
            Y = Y*widthstep/d;
            phase = phasecalc(size(Z,1),X,Y,Z,L);
        catch % If it doesn't work, MES is probably not running
            beep;
            errordlg(error_widthStep);
            return
        end
        if isempty(SLMwindow) % No PTB onscreen window is open
            try % Open PTB onscreen window
                Screen('Preference', 'SkipSyncTests', 1);
                PsychDefaultSetup(2);
                uiN = get(popup_screenN,'Value');
                screenNumber = uiN + 1;
                N = 600;
                [SLMwindow, windowRect] = PsychImaging('OpenWindow', screenNumber, 0);
                dstRects = CenterRectOnPointd([0 0 N N], windowRect(3)/2, windowRect(4)/2);
                setappdata(hfig,'SLMwindow',SLMwindow);
                setappdata(hfig,'dstRects',dstRects);
            catch % If it doesn't work, SLM display number does not exist (SLM is disconnected)
                beep;
                errordlg(error_SLMdisconnect);
                return
            end
        else % There is a PTB onscreen window open
            dstRects = getappdata(hfig,'dstRects');
            imageTexture = Screen('MakeTexture', SLMwindow, phase);
            Screen('DrawTexture', SLMwindow, imageTexture, [], dstRects);
            Screen(SLMwindow, 'Flip');
        end
    else % Debug mode
        widthstep = 0.1;
        d = calc_d();
        X = X*widthstep/d;
        Y = Y*widthstep/d;
        phase = phasecalc(size(Z,1),X,Y,Z,L);
    end
    
    % For both Experiment and Debug modes show phase hologram on duplicate
    % window
    A = findobj('type','figure','name','Duplicate window of hologram');
    if isempty(A) % If phase hologram figure does not exist, create it
        figure('MenuBar','none','Name','Duplicate window of hologram','NumberTitle','off',...
        'Position',[0,0,300,300],'Resize','on');
        imagesc(imresize(phase,[250 250])); axis off; colormap gray;
    else % If phase hologram figure already exists, use it to display hologram
        figure(A);imagesc(imresize(phase,[250 250])); axis off; colormap gray;
    end
    disp('Hologram updated!');
end

function checkCursorCtrl(varargin)
    k = get(check_cursorCtrl,'Value');
    if k == 1
        % If checkbox is checked, change font color of x and y columns to
        % magenta and make x and y columns uneditable
        renderer1 = javax.swing.table.DefaultTableCellRenderer;
        renderer1.setForeground(java.awt.Color.magenta);
        renderer1.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        jtable_coords.getColumnModel.getColumn(1).setCellRenderer(renderer1); % java indexing
        jtable_coords.getColumnModel.getColumn(2).setCellRenderer(renderer1);
        jtable_coords.repaint;
        set(pbutton_addSpot,'Enable','off');
        set(pbutton_delSpot,'Enable','off');
        set(spinner_Nspots_ud(1),'Enable','off');
        set(spinner_Nspots_ud(2),'Enable','off');
        table_coords.setEditable(2,false); % x cannot be edited from table 
        table_coords.setEditable(3,false); % y cannot be edited from table
    else
        % If checkbox is unchecked, x and y columns have black font color
        % and table is editable
        renderer = javax.swing.table.DefaultTableCellRenderer;
        renderer.setForeground(java.awt.Color.black);
        renderer.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        jtable_coords.getColumnModel.getColumn(1).setCellRenderer(renderer);
        jtable_coords.getColumnModel.getColumn(2).setCellRenderer(renderer);
        jtable_coords.getColumnModel.getColumn(3).setCellRenderer(renderer);
        jtable_coords.repaint;
        set(table_coords,'Editable',true);
        set(spinner_Nspots_ud(1),'Enable','on');
        set(spinner_Nspots_ud(2),'Enable','on');
        table_coords.setEditable(2,true); % x can now be edited from table 
        table_coords.setEditable(3,true); % y can now be edited from table

        if (jtable_coords.getRowCount == Nmax)
            set(pbutton_addSpot,'Enable','off');
            set(pbutton_delSpot,'Enable','on');
        end
        if (jtable_coords.getRowCount < Nmax)
            set(pbutton_addSpot,'Enable','on');
            if (jtable_coords.getRowCount > 0)
            	set(pbutton_delSpot,'Enable','on');
            else
                set(pbutton_activateAllSpots,'Enable','off');
                set(pbutton_delSpot,'Enable','off');
            end
        end  
    end
end

function drawSpotsonImage(varargin)
    k = get(check_cursorCtrl,'Value');
    if k == 1 % Cursor contrl is ON
        % Allow user to adjust positions of ACTIVE spots on image
        [sX,sY,Aind] = get_ActivesXYZL(table_coords);
        if isempty(sX)
            spinner_Nspots_inc_Callback;
            sX = 0; sY = 0; Aind = 1;
        end

        modeID = get(popup_mode,'Value');
        if modeID == 1 % Experiment mode
            try
                mth = bgmanage_image('getnearest');
            catch
                beep;
                errordlg(error_MESnotrunning);
                return
            end
            try
                image = get(mth,1,'IMAGE');
                imageDim = size(image);

                A = findobj('type','figure','name','SLM Uncaging Spots');
                if isempty(A)
                    figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                          'Position',[300,0,600,600],'Resize','on');
                    show2Pimage(image);
                    set(toggle_measureDist,'Value',0);
                    set(toggle_measureDist,'ForegroundColor',[0 0 0]);
                else
                    figure(A); show2Pimage(image);
                end
                
                [pX,pY] = uncenterOrigin(sX,sY,imageDim);
                for i = 1:size(pX)
                    n = Aind(i);
                    p(i) = impoint(gca,[pX(i),pY(i)]);
                    api(i) = iptgetapi(p(i));
                    api(i).setColor('m');
                    api(i).addNewPositionCallback(@(pos) cursorPosChange(pos,n));
                    fcn = makeConstrainToRectFcn('impoint',get(gca,'XLim'),get(gca,'YLim'));
                    api(i).setPositionConstraintFcn(fcn);
                end
                if get(check_showLabels,'Value') == 1
                    for i = 1:size(pX)
                        n = Aind(i);
                        api(i).setString(num2str(n));
                    end
                end
            catch
                beep;
                errordlg(error_no2Pimage);
                return
            end
        else % Debug mode
            try
                image = imread(sample_image);
            catch
                image = zeros(800);
            end
            imageDim = size(image);

            A = findobj('type','figure','name','SLM Uncaging Spots');
            if isempty(A)
                figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                      'Position',[300,0,600,600],'Resize','on');
                show2Pimage(image);
                set(toggle_measureDist,'Value',0);
                set(toggle_measureDist,'ForegroundColor',[0 0 0]);
            else
                figure(A); show2Pimage(image);
            end

            [pX,pY] = uncenterOrigin(sX,sY,imageDim);
            for i = 1:size(pX)
                n = Aind(i);
                p(i) = impoint(gca,[pX(i),pY(i)]);
                api(i) = iptgetapi(p(i));
                api(i).setColor('m');
                api(i).addNewPositionCallback(@(pos) cursorPosChange(pos,n));
                fcn = makeConstrainToRectFcn('impoint',get(gca,'XLim'),get(gca,'YLim'));
                api(i).setPositionConstraintFcn(fcn);
            end
            if get(check_showLabels,'Value') == 1
                for i = 1:size(pX)
                    n = Aind(i);
                    api(i).setString(num2str(n));
                end
            end
        end
    else % Cursor control is OFF
        %Fix spot positions on image
        rowCount = jtable_coords.getRowCount;
        if rowCount > 0
            [sX,sY,Aind] = get_ActivesXYZL(table_coords);
            update_crossHairs(sX,sY,Aind);
        else % If there are no spots, just show image
            modeID = get(popup_mode,'Value');
            if modeID == 1 % Experiment mode
                try
                    mth = bgmanage_image('getnearest');
                catch
                    beep;
                    errordlg(error_MESnotrunning);
                    return
                end
                try
                    image = get(mth,1,'IMAGE');
                    
                    A = findobj('type','figure','name','SLM Uncaging Spots');
                    if isempty(A)
                        figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                              'Position',[300,0,600,600],'Resize','on');
                        show2Pimage(image);
                        set(toggle_measureDist,'Value',0);
                        set(toggle_measureDist,'ForegroundColor',[0 0 0]);
                    else
                        figure(A); show2Pimage(image);
                        end
                catch
                    beep;
                    errordlg(error_no2Pimage);
                    return
                end
            else % Debug mode
                try
                    image = imread(sample_image);
                catch
                    image = zeros(800);
                end

                A = findobj('type','figure','name','SLM Uncaging Spots');
                if isempty(A)
                    figure('Name','SLM Uncaging Spots','NumberTitle','off',...
                          'Position',[300,0,600,600],'Resize','on');
                    show2Pimage(image);
                    set(toggle_measureDist,'Value',0);
                    set(toggle_measureDist,'ForegroundColor',[0 0 0]);
                else
                    figure(A); show2Pimage(image);
                end
            end
        end
    end
end


function show2Pimage(image)
    imagesc(imrotate(image,90)); colormap(gray); axis off;
    imageDim = size(image);
    
    if get(check_showUncagingArea,'Value') == 1
        % Draw square or circle to delineate uncaging area
        if get(popup_mode,'Value') == 1 % Experiment mode
            widthstep = get(mth,1,'WidthStep');
        else % Debug mode
            widthstep = 0.1;
        end

        if get(popup_objective,'Value') == 1 % Nikon 60x
            w = round(28/widthstep); % microns/(microns/pixel)
            h = round(28/widthstep);
        else % Zeiss 20x
            w = round(70/widthstep); % microns/(microns/pixel)
            h = round(70/widthstep);
        end
        hold on;
        % rectangular FOV
%         rectangle('Position',[imageDim(1)/2-w/2 imageDim(2)/2-h/2 w h],...
%             'LineWidth',1,'EdgeColor','Yellow');
        
        % circular FOV
        theta = 0:pi/50:2*pi;
        r = w/2;
        xcircle = r * cos(theta) + imageDim(1)/2;
        ycircle = r * sin(theta) + imageDim(2)/2;
        plot(xcircle,ycircle,'y','LineWidth',1);
        hold off;
    end

    if get(check_showRefLines,'Value') == 1
        % Draw reference lines (vertical and horizontal lines through center)
        hold on;
        line([0,imageDim(1)],[imageDim(2)/2,imageDim(2)/2],'Linewidth',1,'Color','Yellow');
        line([imageDim(1)/2,imageDim(1)/2],[0,imageDim(2)],'Linewidth',1,'Color','Yellow');
        hold off;
    end
end


function [mtable, buttons] = createTable(varargin)
    % Edited version of Yair Altman's createTable.m
    % http://de.mathworks.com/matlabcentral/fileexchange/14225-java-based-data-table
          
          if ~usejava('swing')
              error('createTable:NeedSwing','Java tables require Java Swing.');
          end

          % Process optional arguments
          paramsStruct = processArgs(varargin{:});

          hContainer = handle(paramsStruct.container);
          if isa(hContainer,'figure') || isa(hContainer,'matlab.ui.Figure')
              pnContainerPos = getpixelposition(paramsStruct.container,0);  % Fix for Matlab 7.0.4 as per Sebastian Hölz
              pnContainerPos(1:2) = 0;
          else
              pnContainerPos = getpixelposition(paramsStruct.container,1);  % Fix for Matlab 7.0.4 as per Sebastian Hölz
          end

          % Get handle to parent figure
          hFig = ancestor(paramsStruct.container,'figure');

          % Determine whether table manipulation buttons are requested
          if paramsStruct.buttons
              margins = [1,30,0,-30];  % With buttons
          else
              margins = [1,1,0,0];   % No buttons
          end

          % Get the uitable's required position within the container
          tablePosition = pnContainerPos + margins;    % Relative to the figure

          % Start with dummy data, just so that uitable can be initialized 
          % (or use supplied data, if available)
          if isempty(paramsStruct.data)
              numRows = 0;
              numCols = length(paramsStruct.headers);
              paramsStruct.data = zeros(1,numCols);
          else
              numRows = size(paramsStruct.data,1);
          end

          % Create a sortable uitable within the container
          try
              % use the old uitable (Matlab R2008+)
              mtable = uitable('v0', hFig, 'position',tablePosition, 'Data',...
                  paramsStruct.data, 'ColumnNames',paramsStruct.headers);
          catch
              mtable = uitable(hFig, 'position',tablePosition, 'Data',...
                  paramsStruct.data, 'ColumnNames',paramsStruct.headers);
          end
          mtable.setNumRows(numRows);
          set(mtable,'units','normalized');  % this will resize the table whenever its container is resized

          jtable = mtable.getTable;

          jtable.putClientProperty('terminateEditOnFocusLost', java.lang.Boolean.TRUE);

          if ~isempty(which('TableSorter'))
              % Add TableSorter as TableModel listener
              sorter = TableSorter(jtable.getModel());  %(table.getTableModel);
              %tablePeer = UitablePeer(sorter);  % This is not accepted by UitablePeer... - see comment above
              jtable.setModel(sorter);
              sorter.setTableHeader(jtable.getTableHeader());

              % Set the header tooltip (with sorting instructions)
              jtable.getTableHeader.setToolTipText('<html>&nbsp;<b>Click</b> to sort up; <b>Shift-click</b> to sort down<br>&nbsp;<b>Ctrl-click</b> (or <b>Ctrl-Shift-click</b>) to sort secondary&nbsp;<br>&nbsp;<b>Click again</b> to change sort direction<br>&nbsp;<b>Click a third time</b> to return to unsorted view<br>&nbsp;<b>Right-click</b> to select entire column</html>');
          else
              % Set the header tooltip (no sorting instructions...)
              jtable.getTableHeader.setToolTipText('<html>&nbsp;<b>Click</b> to select entire column<br>&nbsp;<b>Ctrl-click</b> (or <b>Shift-click</b>) to select multiple columns&nbsp;</html>');
          end

          % Store the uitable's handle within the container's userdata, for later use
          set(paramsStruct.container,'userdata',[get(paramsStruct.container,'userdata'), mtable]);  % add to parent userdata, so we have a handle for deletion

          % Enable multiple row selection, auto-column resize, and auto-scrollbars
          scroll = mtable.TableScrollPane;
          scroll.setVerticalScrollBarPolicy(scroll.VERTICAL_SCROLLBAR_AS_NEEDED);
          scroll.setHorizontalScrollBarPolicy(scroll.HORIZONTAL_SCROLLBAR_AS_NEEDED);
          jtable.setSelectionMode(javax.swing.ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
          jtable.setAutoResizeMode(jtable.AUTO_RESIZE_SUBSEQUENT_COLUMNS)

          % Set the jtable name based on the containing panel's tag
          basicTagName = get(paramsStruct.container,'tag');
          jtable.setName([basicTagName 'Table']);

          % Move the selection to first table cell (if any data available)
          if (jtable.getRowCount > 0)
              jtable.changeSelection(0,0,false,false);
          end

          % Process optional args
          processParams(paramsStruct,mtable,jtable);

          % Create table manipulation buttons
          if paramsStruct.buttons
              buttons = createManipulationButtons(paramsStruct.container,mtable);
          else
              buttons = [];
          end

    % Process optional arguments
    function paramsStruct = processArgs(varargin)

        % Get the properties in either direct or P-V format
        [regParams, pvPairs] = parseparams(varargin);

        % Fix args in case of P-V mismatch
        if mod(numel(pvPairs),2)
            regParams{end+1} = pvPairs{1};
            pvPairs(1) = [];
        end

        % Now process the optional P-V params
        try
            % Initialize
            paramName = [];
            paramsStruct = [];
            paramsStruct.container = [];
            paramsStruct.headers = {'A','B','C'};  % 3 columns by default
            paramsStruct.data = {};
            paramsStruct.buttons = true;
            paramsStruct.imagecolumns = {};
            paramsStruct.imagetooltipheight = 300;  % 300px by default (max)
            paramsStruct.extra = {};

            % Parse the regular (non-named) params in recption order
            if length(regParams)>0,  paramsStruct.container = regParams{1};  end  %#ok
            if length(regParams)>1,  paramsStruct.headers   = regParams{2};  end
            if length(regParams)>2,  paramsStruct.data      = regParams{3};  end
            if length(regParams)>3,  paramsStruct.buttons   = regParams{4};  end

            % Parse the optional param PV pairs
            supportedArgs = {'container','headers','data','buttons','imagecolumns','imagetooltipheight'};
            while ~isempty(pvPairs)

                % Ensure basic format is valid
                paramName = '';
                if ~ischar(pvPairs{1})
                    error('YMA:createTable:invalidProperty','Invalid property passed to createTable');
                elseif length(pvPairs) == 1
                    error('YMA:createTable:noPropertyValue',['No value specified for property ''' pvPairs{1} '''']);
                end

                % Process parameter values
                paramName  = pvPairs{1};
                paramValue = pvPairs{2};
                pvPairs(1:2) = [];
                if any(strncmpi(paramName,supportedArgs,length(paramName)))
                    paramsStruct.(lower(paramName)) = paramValue;
                else
                    paramsStruct.extra = {paramsStruct.extra{:} paramName paramValue};
                end
            end  % loop pvPairs

            % Create a panel spanning entire figure area, if container handle was not supplied
            if isempty(paramsStruct.container) || ~ishandle(paramsStruct.container)
                paramsStruct.container = uipanel('parent',gcf,'tag','TablePanel');
            end

            % Set default header names, if not supplied
            if isempty(paramsStruct.headers)
                if isempty(paramsStruct.data)
                    paramsStruct.headers = {' '};
                else
                    paramsStruct.headers = cellstr(char('A'-1+(1:size(paramsStruct.data,2))'))';
                end
            elseif ischar(paramsStruct.headers)
                paramsStruct.headers = {paramsStruct.headers};
            end

            % Convert data to cell-format (if not so already)
            if ~iscell(paramsStruct.data)
                numCols = size(paramsStruct.data,2);
                paramsStruct.data = mat2cell(paramsStruct.data,...
                    ones(1,size(paramsStruct.data,1)),ones(1,numCols));
            end

            % Ensure a logical-convertible buttons flag
            if ischar(paramsStruct.buttons)
                switch lower(paramsStruct.buttons)
                    case 'on',  paramsStruct.buttons = true;
                    case 'off', paramsStruct.buttons = false;
                    otherwise
                        error('YMA:createTable:invalidProperty','Invalid buttons property value: must be ''on'', ''off'', 1, 0, true or false');
                end
            elseif isempty(paramsStruct.buttons) || ~(isnumeric(paramsStruct.buttons)...
                    || islogical(paramsStruct.buttons))
                error('YMA:createTable:invalidProperty','Invalid buttons property value: must be ''on'', ''off'', 1, 0, true or false');
            end
        catch
            if ~isempty(paramName),  paramName = [' ''' paramName ''''];  end
            error('YMA:createTable:invalidProperty',['Error setting createTable property'...
                paramName ':' char(10) lasterr]);
        end
    end  % processArgs

    function processParams(paramsStruct,mtable,jtable)
        try
            % Process regular extra parameters
            paramName = '';
            th = jtable.getTableHeader;
            container = get(mtable,'uicontainer');
            for argIdx = 1 : 2 : length(paramsStruct.extra)
                if argIdx<2
                    % We need this pause to let java complete all table rendering
                    % TODO: We should really use calls to awtinvoke() instead, though...
                    pause(0.05);
                end
                if (length(paramsStruct.extra) > argIdx)   % ensure the arg value is there...
                    paramsStruct.extra{argIdx}(1) = upper(paramsStruct.extra{argIdx}(1));  % property names always start with capital letters...
                    paramName  = paramsStruct.extra{argIdx};
                    paramValue = paramsStruct.extra{argIdx+1};
                    propMethodName = ['set' paramName];

                    % First try to modify the container
                    try
                        set(container, paramName, paramValue);
                    catch
                        try % if ismethod(mtable,propMethodName)
                            % No good, so try the mtable...
                            set(mtable, paramName, paramValue);
                        catch %elseif ismethod(jtable,propMethodName)
                            try
                                % sometimes set(t,x,y) failes but t.setX(y) is ok...
                                javaMethod(propMethodName, mtable, paramValue);
                            catch
                                try
                                    % Try to modify the underlying JTable itself
                                    if isprop(jtable, paramName)
                                        set(jtable, paramName, paramValue);
                                    else
                                        error('noSuchProp');
                                    end
                                catch
                                    try
                                        javaMethod(propMethodName, jtable, paramValue);
                                    catch
                                        try
                                            % Try to modify the table header...
                                            set(th, paramName, paramValue);
                                        catch
                                            javaMethod(propMethodName, th, paramValue);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end  % for argIdx

            % Process requested image columns
            if ~isempty(which('ImageCellRenderer')) && ~isempty(paramsStruct.imagecolumns)
                if ischar(paramsStruct.imagecolumns)
                    % Maybe a header name?
                    jtable.getColumn(paramsStruct.imagecolumns).setCellRenderer(ImageCellRenderer(paramsStruct.imagetooltipheight));
                elseif iscellstr(paramsStruct.imagecolumns)
                    % Cell array of header names
                    for argIdx = 1 : length(paramsStruct.imagecolumns)
                        jtable.getColumn(paramsStruct.imagecolumns{argIdx}).setCellRenderer(ImageCellRenderer(paramsStruct.imagetooltipheight));
                        drawnow;
                    end
                else
                    % Try to treat as a numeric index array
                    for argIdx = 1 : length(paramsStruct.imagecolumns)
                        colIdx = paramsStruct.imagecolumns(argIdx) - 1;  % assume 1-based indexing
                        %jtable.setEditable(colIdx,0);  % images are editable!!!
                        jtable.getColumnModel.getColumn(colIdx).setCellRenderer(ImageCellRenderer(paramsStruct.imagetooltipheight));
                        drawnow;
                    end
                end
                 drawnow;
            elseif ~isempty(paramsStruct.imagecolumns)  % i.e., missing Renderer
                warning('YMA:createTable:missingJavaClass','Cannot set image columns: ImageCellRenderer.class is missing from the Java class path');
            end
            jtable.repaint;

            % Process UIContextMenu
            try cm = get(container,'uicontextmenu'); catch cm=[]; end  % fails in HG2
            if ~isempty(cm)
                popupMenu = jtable.getRowHeaderPopupMenu;
                %popupMenu.list;
                popupMenu.removeAll; drawnow; pause(0.1);
                cmChildren = get(cm,'child');
                itemNum = 0;
                for cmChildIdx = length(cmChildren) : -1 : 1
                    if itemNum == 6
                        % add 2 hidden separators which will be removed by the Matlab mouse listener...
                        popupMenu.addSeparator;
                        popupMenu.addSeparator;
                        popupMenu.getComponent(5).setVisible(0);
                        popupMenu.getComponent(6).setVisible(0);
                        itemNum = 8;
                    end
                    % Add a possible separator
                    if strcmpi(get(cmChildren(cmChildIdx),'Separator'),'on')
                        popupMenu.addSeparator;
                        itemNum = itemNum + 1;
                    end
                    if itemNum == 6
                        % add 2 hidden separators which will be removed by the Matlab mouse listener...
                        popupMenu.addSeparator;
                        popupMenu.addSeparator;
                        popupMenu.getComponent(5).setVisible(0);
                        popupMenu.getComponent(6).setVisible(0);
                        itemNum = 8;
                    end
                    % Add the main menu item
                    jMenuItem = javax.swing.JMenuItem(get(cmChildren(cmChildIdx),'Label'));
                    set(jMenuItem,'ActionPerformedCallback',get(cmChildren(cmChildIdx),'Callback'));
                    popupMenu.add(jMenuItem);
                    itemNum = itemNum + 1;
                end
                for extraIdx = itemNum+1 : 7
                    popupMenu.addSeparator;
                    popupMenu.getComponent(extraIdx-1).setVisible(0);
                end
                drawnow;
            end

        catch
            if ~isempty(paramName),  paramName = [' ''' paramName ''''];  end
            error('YMA:createTable:invalidProperty',['Error setting createTable property' paramName ':' char(10) lasterr]);
        end
    end  % processParams
end

function varargout = spinner(varargin)
    % Edited version of Steve Simon's spinner.m
    % http://www.mathworks.com/matlabcentral/fileexchange/5881-spinner

    % quick return, if they want the spinner info
    if nargin == 1 && nargout == 1
        varargout{1} = spinnerdata(varargin{1});
        return
    end

    % list of valid properties
    validprops = {'position';...
                  'min';...
                  'max';...
                  'startvalue';...
                  'step';...
                  'parent';...
                  'callback';...
                  'tag'};

    % default values              
    pos = [20 20 60 20];
    minimum = 0;
    maximum = 1;
    step = 0.1;
    start_value = 1;
    parent = [];
    callback = '';
    tag = 'spinner';

    if mod(nargin,2) ~= 0
        error('Incorrect number of inputs.  Must be an even number of inputs.');
    end

    % parse inputs
    for n = 1:2:nargin
        prop = lower(varargin{n});
        val = varargin{n+1};

        ind = strmatch(prop,validprops);
        if isempty(ind)
            ind = 0;
        end

        switch ind
            case 1 %Position
                if ~isnumeric(val) || any(size(val) ~= [1,4])
                    error('Position must be numeric, 1 by 4 vector.')
                end
                pos = val;
            case 2 %Min
                if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                    error('Min must be a finite numeric scalar.')
                end
                minimum = val;
            case 3 %Max       
                if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                    error('Max must be a finite numeric scalar.')
                end
                maximum = val;
            case 4 %StartValue
                if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                    error('StartValue must be a finite numeric scalar.')
                end
                start_value = val;
            case 5 %Step
                if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                    error('Step must be a finite numeric scalar.')
                end
                step = val;
            case 6 %Parent
                if isempty(val) || ~ishandle(val) || ~any(strcmp(get(val,'Type'),{'figure';'uipanel'}))
                    parent = val;
                end
            case 7 %Callback
                if ~ischar(val) && ~isa(val,'function_handle') && ...
                   (~iscell(val) || ...
                      (~ischar(val{1})  && ~isa(val{1},'function_handle')))
                      error(['Callback must be a string, function handle, ' ...
                              'or a cell array with a first element that is a ' ...
                              'string or function handle.']);
                end
                callback = val;
            case 8 %Tag
                if ~ischar(val)
                    error('Tag must be a string.')
                end
                tag = val;
            otherwise
                error('Unrecognized property "%s".',varargin{n});
        end
    end

    % more error checking
    if minimum >= maximum
        error('Min must be less than Max.');
    end

    if start_value <minimum || start_value > maximum
        error('StartValue must be between Min and Max.')
    end

    % Parent not specified, use current figure
    if isempty(parent)
        parent = gcf;
    end

    % size for pushbuttons
    push_width = 20;
    push_height = round(pos(4)/2);
    button_width = push_width;
    if mod(button_width,2) ~= 0;
        button_width = push_width - 1;    
    end

    % put background color in proper orientation 1 by 1 by3
    uicontrolcolor = reshape(get(0,'defaultuicontrolbackgroundcolor'),[1,1,3]);

    % array for pushbutton's CData
    button_size = 16;
    mid = button_size/2;
    push_cdata = repmat(uicontrolcolor,button_size,button_size);

    % create arrow shape
    for r = 4:11
        start = mid - r + 8 ;
        last = mid + r - 8;
        push_cdata(r,start:last,:) = 0;
    end

    % create uicontrols
    h_edit = uicontrol('Units','pixels',...
                     'Position',pos,...
                     'Style','edit',...
                     'Tag',[tag '_edit'],...
                     'String',num2str(start_value),...
                     'Value',start_value,...
                     'Min',minimum,...
                     'Max',maximum,...
                     'Parent',parent,...
                     'HorizontalAlignment','left');
    if ispc
        set(h_edit,'BackGroundColor',[1 1 1])
    end

    h_down = uicontrol('Units','pixels',...
                     'Position',[pos(1) + (pos(3) - push_width) - 2, pos(2) + 2, push_width, push_height - 2],...
                     'CData',flipdim(push_cdata,1),...
                     'Tag',[tag '_down'],...
                     'Parent',parent,...
                     'SelectionHighlight','off');
    h_up = uicontrol('Units','pixels',...
                     'Position',[pos(1) + (pos(3) - push_width) - 2, pos(2) + push_height, push_width, pos(4) - push_height - 2],...
                     'CData',push_cdata,...
                     'Tag',[tag '_up'],...
                     'Parent',parent,...
                     'SelectionHighlight','off');

    % structure with useful info                 
    spinner_struct.edit = h_edit;
    spinner_struct.down = h_down;
    spinner_struct.up = h_up;
    spinner_struct.step = step;
    spinner_struct.start_value = start_value;
    spinner_struct.last_valid_value = start_value;
    spinner_struct.callback = callback;
    spinner_struct.tag = tag;

    % store useful info, SPINNERDATA is like a simple GUIDATA
    spinnerdata(h_edit,spinner_struct);

    % callbacks
    set(h_down,'Callback',@increment_down);
    set(h_up,'Callback',@increment_up);
    set(h_edit,'KeyPressFcn',@edit_keypress);

    %outputs
    if(nargout)
        varargout{1} = h_edit;
        varargout{2} = [h_down; h_up];
    end

    % ---------------------------------------------------------
    function edit_keypress(h,e)
        %EDIT_KEYPRESS KeyPressFcn for the edit window

        % get useful info
        s = spinnerdata(h);

        % get information about KeyPress event
        c = e.Character;
        k = e.Key;
        str = get(h,'String');

        % valid number characters
        numbers = {'0';'1';'2';'3';'4';'5';'6';'7';'8';'9'};

        if strcmp(k,'backspace')
            % if it's a backspace, remove the last character
            if numel(str) > 0
                str = str(1:end-1);
            end
        elseif any(strcmp(c,numbers)) || strcmp(c,'.')
            % aonly allow number or '.'
            str = [str c];
        end

        % check the values
        [v,str] = check_value(str,s);
        set(h,'Value',v);

        % switch the focus, then back, so setting the String has an effect.
        uicontrol(s.up);
        uicontrol(h);
        set(h,'String',str);

        % execute the callback
        execute_callback(s);
    end

    % ---------------------------------------------------------
    function execute_callback(s)
        %EXECUTE_CALLBACK execute the callback

        % only execute if there's something in the edit window
        if ~isempty(get(s.edit,'String'))
            if ischar(s.callback)
                evalin('base',s.callback);
            elseif isa(s.callback,'function_handle')
                feval(s.callback,gcbo,[])
            elseif iscell(s.callback)
                feval(s.callback{:})
            end
        end
    end
    
    % ---------------------------------------------------------
    function [v,str] = check_value(str,s)
        %CHECK_VALUE make sure the entry is a valid number

        if ~isnumeric(str)
            % if it's a string, convert to get numeric value
            v = str2num(str);
        else
            % otherwise, reassign the value, convert number to string
            v = str;
            str = num2str(v);
        end

        % return early if the string wasn't a valid number
        if isempty(v) || isempty(str)
            return
        end

        minimum = get(s.edit,'Min');
        maximum = get(s.edit,'Max');

        % make sure value is in range
        if v < minimum
            v = minimum;
            str = num2str(v);
        elseif v > maximum;
            v = maximum;
            str = num2str(v);
        end

        % store the last valid value
        s.last_valid_value = v;
        spinnerdata(s.edit,s);
    end

    % ---------------------------------------------------------
    function increment_down(h,e)
        %INCREMENT_DOWN Callback for down pushbutton

        %get useful info
        s = spinnerdata(h);

        % get string, convert to number, reduce by step
        str = get(s.edit,'String');
        v = str2num(str);
        v = v-s.step;

        % check the values
        [v,str] = check_value(v,s);

        % set the String and Value
        set(s.edit,'String',num2str(v),'Value',v);

        % execute the callbacks
        execute_callback(s);
    end
    
    % ---------------------------------------------------------
    function increment_up(h,e)
        %INCREMENT_DOWN Callback for up pushbutton

        %get useful info
        s = spinnerdata(h);

        % get string, convert to number, reduce by step
        str = get(s.edit,'String');
        v = str2num(str);
        v = v+s.step;

        % check the values
        [v,str] = check_value(v,s);

        % set the String and Value
        set(s.edit,'String',num2str(v),'Value',v);

        % execute the callbacks
        execute_callback(s);
    end
    
    % ---------------------------------------------------------
    function s = spinnerdata(h,val)
        %SPINNERDATA store/return stored value

        if ~strcmp(get(h,'Type'),'figure')
            fig = ancestor(h,'figure');
        else 
            fig = h;
        end

        if nargin == 1 && nargout == 1
            s = getappdata(fig,get_spinnerdata_name);
            if numel(s) > 1
                for n = 1:length(s)
                    hndls = [s(n).edit;s(n).down;s(n).up];
                    if any(h == hndls)
                        s = s(n);
                        return
                    end
                end
            end    
        elseif nargin == 2
            s = getappdata(fig,get_spinnerdata_name);
            if isempty(s)
                setappdata(fig,get_spinnerdata_name,val);
            else
                edit_windows = [s.edit];
                ind = find(val.edit == edit_windows);
                if isempty(ind)
                    s(end+1) = val;
                else
                    s(ind) = val;
                end
                setappdata(fig,get_spinnerdata_name,s);
            end
        end
    end
    
    % ---------------------------------------------------------
    function str = get_spinnerdata_name
    %GET_SPINNERDATA_NAME return name used for appdata field

    str = 'SpinnerAppData';
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             CALCULATIONS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function phase = phasecalc(N_spots,X,Y,Z,L)
    xCoords = X; clear X; % X in pixels
    yCoords = Y; clear Y; % Y in pixels
    zCoords = Z; clear Z; % Z in um
    N = 600;
    x = zeros(1,N,N_spots);
    y = zeros(1,N,N_spots);
    V = zeros(N,N,N_spots);
    AbeCorr = zeros(N,N,N_spots);
    phase_j = zeros(N,N,N_spots);
    
    if get(check_disableCorr,'Value') == 0
        if N_spots > 0
            Zcoeff = get_ActiveZcoeff(table_Zcoeff);
        end
    end
    
    %xy shifts for axial tilt correction
    [xShift,yShift] = calc_xyShift(zCoords);
    
    % Amplitude weighting 
    % x axis
    for j = 1:N_spots
        Ax(j) = 1;
    end
    
    % y axis
    if get(check_yAmpWeight1,'Value') == 1
        % Linear inverse weighting
        m = 0.0097691;
        b = 0.49358;
        Imean = 0.4936;
        Iy = (m*yCoords + b)/Imean; 
        Ay = 1./Iy;
    else
        if get(check_yAmpWeight2, 'Value') == 1
            % Sinc-squared inverse weighting
            a = 0.598;
            b = 0.07298;
            c = -0.4428;
            Iy = (a*sin(b*yCoords+c)./(b*yCoords+c)).^2;
            Ay = 1./Iy;
        else
            for j = 1:N_spots
                Ay(j) = 1;
            end
        end
    end
    
    % z axis
    % Quadratic fit for I vs z plot was obtained with IgorPro
    if get(check_zAmpWeight,'Value') == 1
        a = 0.98244;
        b = 0.00010007;
        c = -0.0019329;
        Iz = (a + b*zCoords + c*zCoords.^2)/a; % Normalized intensity vs z fit
        Az = 1./Iz;
    else
        for j = 1:N_spots
            Az(j) = 1;
        end
    end
    
    A = Ax.*Ay.*Az;    

    AbeCor = zeros(N,N,11);
    for j = 1:N_spots
        % X and Y phases
        x(:,:,j) = xCoords(j)*2*pi*(1:1:N)/N;
        y(:,:,j) = -yCoords(j)*2*pi*(1:1:N)/N;
        [X(:,:,j),Y(:,:,j)] = meshgrid(x(:,:,j),y(:,:,j));
        
        % Z phase
        k = (1:1:N);
        [k_X,k_Y] = meshgrid(k+xShift(j),k+yShift(j)); % Michael: Apply shift only to Z and Vortex function
        z = ((k_X-N/2)/(N/2)).^2 + ((k_Y-N/2)/(N/2)).^2;
        Z(:,:,j) = zCoords(j)*2*pi*z;
        
        % Vortex phase
        V(:,:,j) = L(j)*atan2(k_Y-N/2,k_X-N/2);
        
        % Aberration correction phase
        if get(check_disableCorr,'Value') == 0
            if N_spots >0
                for k = 1:11
                    AbeCor(:,:,k) = Zcoeff(k,j).*Zern_phase(:,:,k);
                end
                AbeCorr(:,:,j) = sum(AbeCor,3);
            end
        end
        
        % Total phase for EACH spot
        phase_j(:,:,j)= X(:,:,j) + Y(:,:,j) + Z(:,:,j) + V(:,:,j) + AbeCorr(:,:,j); 
        
        % Electric field for each spot
        Efield_j(:,:,j) = A(j)*exp(1i*phase_j(:,:,j));
    end
    
    % Total for ALL spots
    totE = sum(Efield_j,3); % electric field
    phase = mod(angle(totE),2*pi)/(2*pi); % phase
end

function [hX,hY,hZ] = calc_hXYZ(sX,sY,sZ)
    Xscale = get(spinner_Xscale,'Value');
    Yscale = get(spinner_Yscale,'Value');
    Zscale = get(spinner_Zscale,'Value');
    RotAngle = get(spinner_angle,'Value');

    hY = sX*Xscale; % Michael said the hologram is off by 90 deg rotation
    hX = sY*Yscale;
    hZ = sZ*Zscale;
    theta = RotAngle;

    rotMatrix = [cosd(theta)  sind(theta);...
                 -sind(theta) cosd(theta)];
    rotXY = rotMatrix*[hX';hY'];
    hX = rotXY(1,:)';
    hY = rotXY(2,:)';
end

function [xShift,yShift] = calc_xyShift(Z)
    xyShift = cell(table_xyShift.getData);
    A = cell2mat(xyShift(:,1));
    activeA = find(A==true); 
    if numel(activeA) == 0 % Case for no x and y shifts required
        xShift(1:numel(Z)) = 0;
        yShift(1:numel(Z)) = 0;
    elseif numel(activeA) == 1 % Only one z value was used for axial tilt alignment
        xShift(1:numel(Z)) = str2double(xyShift{activeA,3});
        yShift(1:numel(Z)) = str2double(xyShift{activeA,4});
    else % Two z values were used for axial tilt alignment
        z1 =  str2double(xyShift{1,2});
        z2 =  str2double(xyShift{2,2});
        x1 =  str2double(xyShift{1,3});
        x2 =  str2double(xyShift{2,3});
        y1 =  str2double(xyShift{1,4});
        y2 =  str2double(xyShift{2,4});
        mx = (x2-x1)/(z2-z1); % Slope of a line defined by 2 points
        bx = x1 - mx*z1; % y-intercept of the line
        my = (y2-y1)/(z2-z1);
        by = y1 - my*z1;
        
        xShift = mx.*Z + bx;
        yShift = my.*Z + by;
    end
end

function [cntrdX,cntrdY] = centerOrigin(uncntrdX, uncntrdY,imageDim)
    % Because Matlab assigns the "origin" in an image figure to be at the top
    % left corner, this function translates the "origin" to the center.
    % Coordinates for hologram are centered but not for positioning +
    % symbols on images to mark uncaging spots
    Xdim = imageDim(2); midX = Xdim/2;
    Ydim = imageDim(1); midY = Ydim/2;
    cntrdX = uncntrdX - midX;
    cntrdY = -uncntrdY + midY;
end

function [uncntrdX,uncntrdY] = uncenterOrigin(cntrdX,cntrdY,imageDim)
    % Coordinates for hologram are centered but not for positioning +
    % symbols on images to mark uncaging spots
    Xdim = imageDim(2); midX = Xdim/2;
    Ydim = imageDim(1); midY = Ydim/2;
    uncntrdX = cntrdX + midX;
    uncntrdY = -(cntrdY - midY);
end

function d = calc_d(varargin)
    % d is the deviation from the zeroth order for 2pi phase gradient.
    % Ref: Astrid van der Horst and Nancy Forde, Opt Exp 16(25), 20987 (2008)
    %   L/M : objective focal length; L is the tube length or reference focal
    %   length, M is the magnification. For a Nikon 60x lens, L = 200 mm
    %   m = f_L2/f_L1 where L1 and L2 are the lenses after the SLM
    %   l : width of the SLM
    %   phi : maximum imposed phase shift
    
    lambda = str2double(get(edit_lambda,'String'));
    if get(popup_objective,'Value') == 1
        M = 60;
    else
        M = 20;
    end
    L = 200; % mm
    phi = 2*pi;
    m = 30/100; % 30mm/100mm
    l = 12; % mm
    d = (L*lambda*phi*1e-3)/(m*M*l*2*pi);
end

function Zern_phase = calc_ZernPhase(varargin)
    % This function generates the phase for aberration correction from
    % Zernike polynomials. This function will only be called if the file 
    % Zern_phase.mat is not in the folder for the SLM software.
    
    N = 600;
    x = linspace(-1,1,N);
    y = linspace(1,-1,N);
    [x,y] = meshgrid(x,y);
    rho = sqrt(x.^2+y.^2);
    theta = atan2(y,x); % in radians
    theta(N/2+1:N,:) = theta(N/2+1:N,:)+2*pi;

    Zpoly(:,:,1) = ones(N,N);
    Zpoly(:,:,2) = rho.*cos(theta);
    Zpoly(:,:,3) = rho.*sin(theta);
    Zpoly(:,:,4) = 2.*(rho.^2)-1;
    Zpoly(:,:,5) = (rho.^2).*sin(2.*theta);
    Zpoly(:,:,6) = (rho.^2).*cos(2.*theta);
    Zpoly(:,:,7) = (3.*(rho.^3)-(2.*rho)).*sin(theta);
    Zpoly(:,:,8) = (3.*(rho.^3)-(2.*rho)).*cos(theta);
    Zpoly(:,:,9) = (rho.^3).*sin(3.*theta);
    Zpoly(:,:,10) = (rho.^3).*cos(3.*theta);
    Zpoly(:,:,11) = 6.*(rho.^4)-(6.*(rho.^2))+1;
    
    Zern_phase(:,:,1) = angle(exp(1i*Zpoly(:,:,1))); 
    Zern_phase(:,:,2) = angle(exp(1i*Zpoly(:,:,2))); 
    Zern_phase(:,:,3) = angle(exp(1i*Zpoly(:,:,3))); 
    Zern_phase(:,:,4) = angle(exp(1i*Zpoly(:,:,4))); 
    Zern_phase(:,:,5) = angle(exp(1i*Zpoly(:,:,5))); 
    Zern_phase(:,:,6) = angle(exp(1i*Zpoly(:,:,6))); 
    Zern_phase(:,:,7) = angle(exp(1i*Zpoly(:,:,7))); 
    Zern_phase(:,:,8) = angle(exp(1i*Zpoly(:,:,8))); 
    Zern_phase(:,:,9) = angle(exp(1i*Zpoly(:,:,9))); 
    Zern_phase(:,:,10) = angle(exp(1i*Zpoly(:,:,10))); 
    Zern_phase(:,:,11) = angle(exp(1i*Zpoly(:,:,11))); 
    
    Zern_phase(:,:,1) = Zern_phase(:,:,1) - min(min(Zern_phase(:,:,1)));
    Zern_phase(:,:,2) = Zern_phase(:,:,2) - min(min(Zern_phase(:,:,2)));
    Zern_phase(:,:,3) = Zern_phase(:,:,3) - min(min(Zern_phase(:,:,3)));
    Zern_phase(:,:,4) = Zern_phase(:,:,4) - min(min(Zern_phase(:,:,4)));
    Zern_phase(:,:,5) = Zern_phase(:,:,5) - min(min(Zern_phase(:,:,5)));
    Zern_phase(:,:,6) = Zern_phase(:,:,6) - min(min(Zern_phase(:,:,6)));
    Zern_phase(:,:,7) = Zern_phase(:,:,7) - min(min(Zern_phase(:,:,7)));
    Zern_phase(:,:,8) = Zern_phase(:,:,8) - min(min(Zern_phase(:,:,8)));
    Zern_phase(:,:,9) = Zern_phase(:,:,9) - min(min(Zern_phase(:,:,9)));
    Zern_phase(:,:,10) = Zern_phase(:,:,10) - min(min(Zern_phase(:,:,10)));
    Zern_phase(:,:,11) = Zern_phase(:,:,11) - min(min(Zern_phase(:,:,11)));

    save Zern_phase.mat Zern_phase
end

end
