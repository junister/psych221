function init(varargin)
    %% Not sure quite how to wrap this if ~dockerWrapper.exists, 
    dockerWrapper.config(varargin{:});
end

