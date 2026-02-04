classdef OCR_Tool_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        ResetButton                    matlab.ui.control.Button
        Panel                          matlab.ui.container.Panel
        StructuraltransformationPanel  matlab.ui.container.Panel
        EnhanceImageButton             matlab.ui.control.Button
        CorrectSkewButton              matlab.ui.control.Button
        tophatButton                   matlab.ui.control.Button
        ThinningButton                 matlab.ui.control.Button
        NoiseReductionCleanUpPanel     matlab.ui.container.Panel
        sizeSpinner                    matlab.ui.control.Spinner
        sizeSpinnerLabel               matlab.ui.control.Label
        DropDown                       matlab.ui.control.DropDown
        MorphologyButton               matlab.ui.control.Button
        InversionButton                matlab.ui.control.Button
        RemoveBackgroundButton         matlab.ui.control.Button
        NoiseRemovalButton             matlab.ui.control.Button
        BasicPreprocessingPanel        matlab.ui.container.Panel
        BinarizeButton                 matlab.ui.control.Button
        IntensityButton                matlab.ui.control.Button
        SharpenButton                  matlab.ui.control.Button
        EnhanceContrastButton          matlab.ui.control.Button
        GrayScaleButton                matlab.ui.control.Button
        UndoButton                     matlab.ui.control.Button
        ChooseRegionDropDown           matlab.ui.control.DropDown
        ChooseRegionLabel              matlab.ui.control.Label
        SelectImageButton              matlab.ui.control.Button
        ExtractedTextLabel             matlab.ui.control.Label
        TextArea                       matlab.ui.control.TextArea
        ApplyOCRButton                 matlab.ui.control.Button
        UIAxesImage                    matlab.ui.control.UIAxes
        UIAxesModify                   matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        Img 
        ModImg
        txt
        ROIPosition
        mode
        historyStack = {};
    end


    methods (Access = private)
        
        function rotated_image = imrotate_white(~, image, rot_angle_degree)
            
                
                rotated_image = imrotate(image, rot_angle_degree,'crop');
    
        end

        function pushToHistory(app)
            app.historyStack{end+1} = app.ModImg;
        end


        end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: SelectImageButton
        function SelectImageButtonPushed(app, event)
            [file, path] = uigetfile({'*.jpg;*.png;*.bmp;*.tif','Image Files (*.jpg, *.png, *.bmp, *.tif)'});
            
            app.mode = 'None';
            app.ChooseRegionDropDown.Value = 'None';
            app.ROIPosition = [];
            app.EnhanceImageButton.Enable = "on";

            if isequal(file, 0)
                disp('No Image Selected');
                return;
            end
            
            fullImagePath = fullfile(path, file);
            
            app.Img = imread(fullImagePath);
            app.ModImg = app.Img;
            imshow(app.Img, 'Parent', app.UIAxesImage);
            title(app.UIAxesImage, 'original Image');

            imshow(app.ModImg, 'Parent', app.UIAxesModify);
            title(app.UIAxesModify, 'Modified Image');

            figure(app.UIFigure);
            drawnow;
        end

        % Button pushed function: ApplyOCRButton
        function ApplyOCRButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            if strcmp(app.mode, 'Preprocess ROI Only')
                pos = round(app.ROIPosition);
                x1 = max(pos(1), 1);
                y1 = max(pos(2), 1);
                x2 = min(x1 + pos(3) - 1, size(app.ModImg, 2));
                y2 = min(y1 + pos(4) - 1, size(app.ModImg, 1));

                roi = app.ModImg(y1:y2, x1:x2, :);
                app.txt = ocr(roi);
            else
                
                app.txt = ocr(app.ModImg);
            end

            recognizedText = app.txt.Text;
            app.TextArea.Value = splitlines(strtrim(recognizedText));
        end

        % Button pushed function: EnhanceImageButton
        function EnhanceImageButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            scaleFactor = 2;
            originalImage = app.ModImg;
            % counter
            originalImage = imresize(originalImage, scaleFactor);
            
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;
        end

        % Button pushed function: ThinningButton
        function ThinningButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                ThinedPatch = bwmorph(roiPatch, 'thin', app.sizeSpinner.Value);
                originalImage(y:y_end, x:x_end, :) = ThinedPatch;
            else
                originalImage = bwmorph(originalImage, 'thin', app.sizeSpinner.Value);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;
            
        

        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end

            app.ModImg = app.Img;
            app.TextArea.Value = "";
            imshow(app.ModImg, 'Parent', app.UIAxesModify);
            % enhance image button
            app.EnhanceImageButton.Enable = 'on';
            %drop down to None
            app.ChooseRegionDropDown.Value = 'None';
            app.mode = 'None';
            %spinner value to one
            app.sizeSpinner.Value = 1;
        end

        % Button pushed function: SharpenButton
        function SharpenButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                SharpenedPatch = imsharpen(roiPatch);
                originalImage(y:y_end, x:x_end, :) = SharpenedPatch;
            else
                originalImage = imsharpen(originalImage);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;
        end

        % Button pushed function: EnhanceContrastButton
        function EnhanceContrastButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                AHistPatch = adapthisteq(roiPatch);
                originalImage(y:y_end, x:x_end, :) = AHistPatch;
            else
                originalImage = adapthisteq(originalImage);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;


        end

        % Button pushed function: GrayScaleButton
        function GrayScaleButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            if size(app.ModImg, 3) == 3
                app.historyStack{end+1} = app.ModImg;
                app.ModImg = rgb2gray(app.ModImg);
            end
            app.ModImg = im2double(app.ModImg);
            imshow(app.ModImg, 'Parent', app.UIAxesModify);
        end

        % Button pushed function: NoiseRemovalButton
        function NoiseRemovalButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                CleanedPatch = medfilt2(roiPatch, [3 3]);
                originalImage(y:y_end, x:x_end, :) = CleanedPatch;
            else
                originalImage = medfilt2(originalImage, [3 3]);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;

            
        end

        % Button pushed function: BinarizeButton
        function BinarizeButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                invertedPatch = imbinarize(roiPatch);
                originalImage(y:y_end, x:x_end, :) = invertedPatch;
            else
                originalImage = imbinarize(originalImage);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;
            
        end

        % Button pushed function: MorphologyButton
        function MorphologyButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
           
            disk_size = app.sizeSpinner.Value;

            morph = app.DropDown.Value;
            se = strel('disk', disk_size);
           
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                switch morph
                case 'Erosion'
                    MorphoPatch = imerode(roiPatch, se);
                case 'Dilation'
                    MorphoPatch = imdilate(roiPatch, se);
                case 'Opening'
                    MorphoPatch = imopen(roiPatch, se);
                case 'Closing'
                    MorphoPatch = imclose(roiPatch, se);
                end
                originalImage(y:y_end, x:x_end, :) = MorphoPatch;
            else
                switch morph
                case 'Erosion'
                    originalImage = imerode(originalImage, se);
                case 'Dilation'
                    originalImage = imdilate(originalImage, se);
                case 'Opening'
                    originalImage = imopen(originalImage, se);
                case 'Closing'
                    originalImage = imclose(originalImage, se);
                end
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;

            

        end

        % Button pushed function: InversionButton
        function InversionButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                invertedPatch = imcomplement(roiPatch);
                originalImage(y:y_end, x:x_end, :) = invertedPatch;
            else
                originalImage =  imcomplement(originalImage);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;            
        end

        % Button pushed function: IntensityButton
        function IntensityButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                HAPatch = imadjust(roiPatch);
                originalImage(y:y_end, x:x_end, :) = HAPatch;
            else
                
                originalImage = imadjust(originalImage);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;


        end

        % Button pushed function: RemoveBackgroundButton
        function RemoveBackgroundButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            disk_size = app.sizeSpinner.Value;
            se = strel('disk', disk_size);
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                RMBackPatch = imbothat(roiPatch, se);
                originalImage(y:y_end, x:x_end, :) = RMBackPatch;
            else
                originalImage = imbothat(originalImage, se);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;

        end

        % Button pushed function: tophatButton
        function tophatButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            disk_size = app.sizeSpinner.Value;
            se = strel('disk', disk_size);
            originalImage = app.ModImg;

            if strcmp(app.mode, 'Preprocess ROI Only')
                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
                
                roiPatch = originalImage(y:y_end, x:x_end, :);
                invertedPatch = imtophat(roiPatch, se);
                originalImage(y:y_end, x:x_end, :) = invertedPatch;
            else
                originalImage = imtophat(originalImage, se);
            end
        
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;
        end

        % Value changed function: ChooseRegionDropDown
        function ChooseRegionDropDownValueChanged(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.mode = app.ChooseRegionDropDown.Value;
            if app.mode == "Preprocess ROI Only"
                app.EnhanceImageButton.Enable = "off";
            else
               app.EnhanceImageButton.Enable = "on";
            end

            if isempty(app.ModImg)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end

            title(app.UIAxesModify, 'Draw a rectangle to select the template region');
            Region = drawrectangle(app.UIAxesModify, 'Color', 'g');

            if isempty(Region)
                uialert(app.UIFigure, 'No region selected', 'Selection Error');
                return;
            end
            
            pos = round(Region.Position);
            app.ROIPosition = pos;
            
            if strcmp(app.mode, 'Crop Image to ROI')
                x1 = max(pos(1), 1);
                y1 = max(pos(2), 1);
                x2 = min(x1 + pos(3) - 1, size(app.ModImg, 2));
                y2 = min(y1 + pos(4) - 1, size(app.ModImg, 1));
                app.ModImg = app.ModImg(y1:y2, x1:x2, :); 
                app.ROIPosition = [];  
            end

            imshow(app.ModImg, 'Parent', app.UIAxesModify);
            if app.mode == "Crop Image to ROI"
                app.ChooseRegionDropDown.Value = 'None';
                app.mode = 'None';
            end
        
        end

        % Button pushed function: CorrectSkewButton
        function CorrectSkewButtonPushed(app, event)
            % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            app.historyStack{end+1} = app.ModImg;
            originalImage = app.ModImg;
            if strcmp(app.mode, 'Preprocess ROI Only')
        

                roi = app.ROIPosition;
                x = max(1, round(roi(1)));
                y = max(1, round(roi(2)));
                w = round(roi(3));
                h = round(roi(4));
                x_end = min(x + w - 1, size(originalImage, 2));
                y_end = min(y + h - 1, size(originalImage, 1));
        
                roiPatch = originalImage(y:y_end, x:x_end, :);
                Patch = roiPatch;
        

                BW = edge(Patch, 'canny');
                [H, T, R] = hough(BW);
                P = houghpeaks(H, 1, 'Threshold', ceil(0.9 * max(H(:))));
                lines = houghlines(BW, T, R, P, 'FillGap', 0.8 * size(roiPatch, 2), 'MinLength', 40);

                if isempty(lines)
                    uialert(app.UIFigure, 'No dominant lines found in ROI.', 'Hough Transform Error');
                    return;
                end

                angle = lines(1).theta;
                if angle < 0
                    rotAngle = 90 - abs(angle);
                else
                    rotAngle = angle - 90;
                end

                rotatedPatch = imrotate_white(app, Patch, rotAngle);

              
                resizedRotatedPatch = imresize(rotatedPatch, [y_end - y + 1, x_end - x + 1]);

                
                if size(originalImage, 3) == 3
                    resizedRotatedPatch = repmat(resizedRotatedPatch, 1, 1, 3); 
                end

                originalImage(y:y_end, x:x_end, :) = resizedRotatedPatch;

            else
        

                BW = edge(originalImage, 'canny');
                [H, T, R] = hough(BW);
                P = houghpeaks(H, 1, 'Threshold', ceil(0.9 * max(H(:))));
                lines = houghlines(BW, T, R, P, 'FillGap', 0.8 * size(originalImage, 2), 'MinLength', 40);

                if isempty(lines)
                    uialert(app.UIFigure, 'No dominant lines found.', 'Hough Transform Error');
                    return;
                end

                angle = lines(1).theta;
                if angle < 0
                    rotAngle = 90 - abs(angle);
                else
                    rotAngle = angle - 90;
                end

                rotatedImg = imrotate_white(app, originalImage, rotAngle);

                if size(originalImage, 3) == 3
                    rotatedImg = repmat(rotatedImg, 1, 1, 3);  % Match RGB
                end

                originalImage = rotatedImg;
            end

   
            imshow(originalImage, 'Parent', app.UIAxesModify);
            app.ModImg = originalImage;


        end

        % Button pushed function: UndoButton
        function UndoButtonPushed(app, event)
           % isempty alert
            if isempty(app.Img)
                uialert(app.UIFigure, 'Please load an image first.', 'No Image Loaded');
                return;
            end
            
            if ~isempty(app.historyStack)
                app.ModImg = app.historyStack{end};  
                app.historyStack(end) = [];          
                imshow(app.ModImg, 'Parent', app.UIAxesModify);
           else
                uialert(app.UIFigure, 'No previous state to undo.', 'Undo Failed');
            end 
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1105 673];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'0.5x', '0.5x', '0.5x', '0.5x', '0.5x', '0.5x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.BackgroundColor = [0.2314 0.302 0.4196];

            % Create UIAxesModify
            app.UIAxesModify = uiaxes(app.GridLayout);
            zlabel(app.UIAxesModify, 'Z')
            app.UIAxesModify.XColor = [0.8118 0.8118 0.8118];
            app.UIAxesModify.XTick = [];
            app.UIAxesModify.YColor = [0.8118 0.8118 0.8118];
            app.UIAxesModify.YTick = [];
            app.UIAxesModify.Box = 'on';
            app.UIAxesModify.Layout.Row = [9 15];
            app.UIAxesModify.Layout.Column = [1 3];

            % Create UIAxesImage
            app.UIAxesImage = uiaxes(app.GridLayout);
            zlabel(app.UIAxesImage, 'Z')
            app.UIAxesImage.XColor = [0.8118 0.8118 0.8118];
            app.UIAxesImage.XTick = [];
            app.UIAxesImage.YColor = [0.8118 0.8118 0.8118];
            app.UIAxesImage.YTick = [];
            app.UIAxesImage.Box = 'on';
            app.UIAxesImage.Layout.Row = [1 7];
            app.UIAxesImage.Layout.Column = [1 3];

            % Create ApplyOCRButton
            app.ApplyOCRButton = uibutton(app.GridLayout, 'push');
            app.ApplyOCRButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyOCRButtonPushed, true);
            app.ApplyOCRButton.BackgroundColor = [0.8784 0.8314 0.7294];
            app.ApplyOCRButton.Layout.Row = 8;
            app.ApplyOCRButton.Layout.Column = 5;
            app.ApplyOCRButton.Text = 'Apply OCR';

            % Create TextArea
            app.TextArea = uitextarea(app.GridLayout);
            app.TextArea.Editable = 'off';
            app.TextArea.Layout.Row = [2 6];
            app.TextArea.Layout.Column = [4 6];

            % Create ExtractedTextLabel
            app.ExtractedTextLabel = uilabel(app.GridLayout);
            app.ExtractedTextLabel.BackgroundColor = [0.8784 0.8314 0.7294];
            app.ExtractedTextLabel.FontWeight = 'bold';
            app.ExtractedTextLabel.Layout.Row = 1;
            app.ExtractedTextLabel.Layout.Column = 5;
            app.ExtractedTextLabel.Text = '             Extracted Text';

            % Create SelectImageButton
            app.SelectImageButton = uibutton(app.GridLayout, 'push');
            app.SelectImageButton.ButtonPushedFcn = createCallbackFcn(app, @SelectImageButtonPushed, true);
            app.SelectImageButton.Layout.Row = 8;
            app.SelectImageButton.Layout.Column = 1;
            app.SelectImageButton.Text = 'Select Image';
            app.SelectImageButton.Icon = fullfile(pathToMLAPP, 'السنين الجامعية', 'الفصل الثاني', 'CV', 'OCR', 'select image.jpg');

            % Create ChooseRegionLabel
            app.ChooseRegionLabel = uilabel(app.GridLayout);
            app.ChooseRegionLabel.BackgroundColor = [0.8784 0.8314 0.7294];
            app.ChooseRegionLabel.HorizontalAlignment = 'right';
            app.ChooseRegionLabel.FontWeight = 'bold';
            app.ChooseRegionLabel.Layout.Row = 7;
            app.ChooseRegionLabel.Layout.Column = 4;
            app.ChooseRegionLabel.Text = 'Choose Region            ';

            % Create ChooseRegionDropDown
            app.ChooseRegionDropDown = uidropdown(app.GridLayout);
            app.ChooseRegionDropDown.Items = {'None', 'Crop Image to ROI', 'Preprocess ROI Only'};
            app.ChooseRegionDropDown.ValueChangedFcn = createCallbackFcn(app, @ChooseRegionDropDownValueChanged, true);
            app.ChooseRegionDropDown.Layout.Row = 7;
            app.ChooseRegionDropDown.Layout.Column = [5 6];
            app.ChooseRegionDropDown.Value = 'None';

            % Create UndoButton
            app.UndoButton = uibutton(app.GridLayout, 'push');
            app.UndoButton.ButtonPushedFcn = createCallbackFcn(app, @UndoButtonPushed, true);
            app.UndoButton.Layout.Row = 8;
            app.UndoButton.Layout.Column = 3;
            app.UndoButton.Text = 'Undo';
            app.UndoButton.Icon = fullfile(pathToMLAPP, 'السنين الجامعية', 'الفصل الثاني', 'CV', 'OCR', 'ocr.png');

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.BackgroundColor = [0.902 0.902 0.902];
            app.Panel.Layout.Row = [9 15];
            app.Panel.Layout.Column = [4 6];

            % Create BasicPreprocessingPanel
            app.BasicPreprocessingPanel = uipanel(app.Panel);
            app.BasicPreprocessingPanel.Title = '  Basic Preprocessing ';
            app.BasicPreprocessingPanel.BackgroundColor = [0.8784 0.8314 0.7294];
            app.BasicPreprocessingPanel.FontWeight = 'bold';
            app.BasicPreprocessingPanel.Position = [10 19 148 262];

            % Create GrayScaleButton
            app.GrayScaleButton = uibutton(app.BasicPreprocessingPanel, 'push');
            app.GrayScaleButton.ButtonPushedFcn = createCallbackFcn(app, @GrayScaleButtonPushed, true);
            app.GrayScaleButton.Position = [18 194 107 34];
            app.GrayScaleButton.Text = 'GrayScale';

            % Create EnhanceContrastButton
            app.EnhanceContrastButton = uibutton(app.BasicPreprocessingPanel, 'push');
            app.EnhanceContrastButton.ButtonPushedFcn = createCallbackFcn(app, @EnhanceContrastButtonPushed, true);
            app.EnhanceContrastButton.Position = [19 151 106 34];
            app.EnhanceContrastButton.Text = 'Enhance Contrast';

            % Create SharpenButton
            app.SharpenButton = uibutton(app.BasicPreprocessingPanel, 'push');
            app.SharpenButton.ButtonPushedFcn = createCallbackFcn(app, @SharpenButtonPushed, true);
            app.SharpenButton.Position = [18 106 107 34];
            app.SharpenButton.Text = 'Sharpen';

            % Create IntensityButton
            app.IntensityButton = uibutton(app.BasicPreprocessingPanel, 'push');
            app.IntensityButton.ButtonPushedFcn = createCallbackFcn(app, @IntensityButtonPushed, true);
            app.IntensityButton.Position = [18 62 107 34];
            app.IntensityButton.Text = 'Intensity';

            % Create BinarizeButton
            app.BinarizeButton = uibutton(app.BasicPreprocessingPanel, 'push');
            app.BinarizeButton.ButtonPushedFcn = createCallbackFcn(app, @BinarizeButtonPushed, true);
            app.BinarizeButton.Position = [20 23 105 34];
            app.BinarizeButton.Text = 'Binarize';

            % Create NoiseReductionCleanUpPanel
            app.NoiseReductionCleanUpPanel = uipanel(app.Panel);
            app.NoiseReductionCleanUpPanel.Title = ' Noise Reduction & CleanUp';
            app.NoiseReductionCleanUpPanel.BackgroundColor = [0.8784 0.8314 0.7294];
            app.NoiseReductionCleanUpPanel.FontWeight = 'bold';
            app.NoiseReductionCleanUpPanel.Position = [172 19 184 264];

            % Create NoiseRemovalButton
            app.NoiseRemovalButton = uibutton(app.NoiseReductionCleanUpPanel, 'push');
            app.NoiseRemovalButton.ButtonPushedFcn = createCallbackFcn(app, @NoiseRemovalButtonPushed, true);
            app.NoiseRemovalButton.Position = [39 161 107 34];
            app.NoiseRemovalButton.Text = 'Noise Removal';

            % Create RemoveBackgroundButton
            app.RemoveBackgroundButton = uibutton(app.NoiseReductionCleanUpPanel, 'push');
            app.RemoveBackgroundButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveBackgroundButtonPushed, true);
            app.RemoveBackgroundButton.Position = [39 204 106 34];
            app.RemoveBackgroundButton.Text = {'Remove '; 'Background'};

            % Create InversionButton
            app.InversionButton = uibutton(app.NoiseReductionCleanUpPanel, 'push');
            app.InversionButton.ButtonPushedFcn = createCallbackFcn(app, @InversionButtonPushed, true);
            app.InversionButton.Position = [40 120 108 34];
            app.InversionButton.Text = 'Inversion';

            % Create MorphologyButton
            app.MorphologyButton = uibutton(app.NoiseReductionCleanUpPanel, 'push');
            app.MorphologyButton.ButtonPushedFcn = createCallbackFcn(app, @MorphologyButtonPushed, true);
            app.MorphologyButton.Position = [38 73 108 34];
            app.MorphologyButton.Text = 'Morphology';

            % Create DropDown
            app.DropDown = uidropdown(app.NoiseReductionCleanUpPanel);
            app.DropDown.Items = {'Erosion', 'Dilation', 'Opening', 'Closing'};
            app.DropDown.Position = [4 29 77 34];
            app.DropDown.Value = 'Erosion';

            % Create sizeSpinnerLabel
            app.sizeSpinnerLabel = uilabel(app.NoiseReductionCleanUpPanel);
            app.sizeSpinnerLabel.HorizontalAlignment = 'right';
            app.sizeSpinnerLabel.Position = [90 36 26 22];
            app.sizeSpinnerLabel.Text = 'size';

            % Create sizeSpinner
            app.sizeSpinner = uispinner(app.NoiseReductionCleanUpPanel);
            app.sizeSpinner.Limits = [1 Inf];
            app.sizeSpinner.Position = [130 36 53 22];
            app.sizeSpinner.Value = 1;

            % Create StructuraltransformationPanel
            app.StructuraltransformationPanel = uipanel(app.Panel);
            app.StructuraltransformationPanel.Title = ' Structural transformation';
            app.StructuraltransformationPanel.BackgroundColor = [0.8784 0.8314 0.7294];
            app.StructuraltransformationPanel.FontWeight = 'bold';
            app.StructuraltransformationPanel.Position = [364 20 160 264];

            % Create ThinningButton
            app.ThinningButton = uibutton(app.StructuraltransformationPanel, 'push');
            app.ThinningButton.ButtonPushedFcn = createCallbackFcn(app, @ThinningButtonPushed, true);
            app.ThinningButton.Position = [30 203 102 34];
            app.ThinningButton.Text = 'Thinning';

            % Create tophatButton
            app.tophatButton = uibutton(app.StructuraltransformationPanel, 'push');
            app.tophatButton.ButtonPushedFcn = createCallbackFcn(app, @tophatButtonPushed, true);
            app.tophatButton.Position = [30 153 102 34];
            app.tophatButton.Text = 'tophat';

            % Create CorrectSkewButton
            app.CorrectSkewButton = uibutton(app.StructuraltransformationPanel, 'push');
            app.CorrectSkewButton.ButtonPushedFcn = createCallbackFcn(app, @CorrectSkewButtonPushed, true);
            app.CorrectSkewButton.Position = [30 109 101 34];
            app.CorrectSkewButton.Text = 'Correct Skew';

            % Create EnhanceImageButton
            app.EnhanceImageButton = uibutton(app.StructuraltransformationPanel, 'push');
            app.EnhanceImageButton.ButtonPushedFcn = createCallbackFcn(app, @EnhanceImageButtonPushed, true);
            app.EnhanceImageButton.Position = [30 66 102 34];
            app.EnhanceImageButton.Text = 'Enhance Image';

            % Create ResetButton
            app.ResetButton = uibutton(app.GridLayout, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Layout.Row = 8;
            app.ResetButton.Layout.Column = 2;
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Icon = fullfile(pathToMLAPP, 'السنين الجامعية', 'الفصل الثاني', 'CV', 'OCR', 'reset.png');

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = OCR_Tool_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end