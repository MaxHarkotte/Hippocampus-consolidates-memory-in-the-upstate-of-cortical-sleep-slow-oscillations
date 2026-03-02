function [cleanTable, removedEvents] = cleanAndRepairTTL(tbl, onLabel, offLabel, durationRange)
% cleanAndRepairTTL
%   Cleans and repairs TTL event logs so that ON and OFF events alternate.
%
% INPUTS
%   tbl            - Table with at least 'type' and 'sample' columns
%   onLabel        - String for ON event type (e.g., 'StimON')
%   offLabel       - String for OFF event type (e.g., 'StimOFF')
%   durationRange  - [min max] allowed duration in samples (e.g., [995 1005])
%
% OUTPUTS
%   cleanTable     - Cleaned and repaired table with alternating events (ON then OFF)
%   removedEvents  - Table of events that were removed / rejected

    % --- Basic checks ---
    if ~istable(tbl)
        error('Input must be a table.');
    end
    if ~any(strcmp(tbl.Properties.VariableNames, 'type'))
        error('Table must contain a ''type'' column.');
    end
    if ~any(strcmp(tbl.Properties.VariableNames, 'sample'))
        error('Table must contain a ''sample'' column.');
    end

    if ~isnumeric(tbl.sample)
        error('The ''sample'' column must be numeric.');
    end

    % --- Normalize type column to string array for easy comparison ---
    % Handles cellstr, char, categorical, string
    typeCol = tbl.type;
    if iscell(typeCol)
        types = string(typeCol);        % cell array of char -> string
    elseif iscategorical(typeCol)
        types = string(cellstr(typeCol));
    elseif isstring(typeCol)
        types = typeCol;
    elseif ischar(typeCol)
        types = string(cellstr(typeCol));
    else
        error('Unsupported type for tbl.type');
    end
    tbl.type = types; % replace so downstream code can use string ops

    % Sort by sample (safety)
    tbl = sortrows(tbl, 'sample');

    % Keep only relevant events (ON/OFF labels)
    keepMask = tbl.type == string(onLabel) | tbl.type == string(offLabel);
    relevantTbl = tbl(keepMask, :);

    % Track removed events so we can return them later
    removedEvents = tbl(~keepMask, :);  % events with other labels removed already

    % --- Repair step 1: remove immediate consecutive duplicates to force alternation ---
    n = height(relevantTbl);
    if n == 0
        cleanTable = relevantTbl;
        return
    end

    keep = true(n,1);
    prevType = relevantTbl.type(1);
    for i = 2:n
        if relevantTbl.type(i) == prevType
            % Mark duplicate (consecutive same type) for removal
            keep(i) = false;
        else
            prevType = relevantTbl.type(i);
        end
    end
    repairedTbl = relevantTbl(keep, :);
    removedEvents = [removedEvents; relevantTbl(~keep, :)];

    % After this step, sequence starts with whatever first event was.
    % If you want to enforce that the sequence must start with ON, optionally remove a leading OFF:
    if ~isempty(repairedTbl) && repairedTbl.type(1) ~= string(onLabel)
        % drop the first row (leading OFF), and record it as removed
        removedEvents = [removedEvents; repairedTbl(1, :)];
        repairedTbl(1, :) = [];
    end

    % If there's now an odd number of rows (incomplete final OFF), drop last row
    if mod(height(repairedTbl), 2) == 1
        % Last row has no matching partner -> remove and record
        removedEvents = [removedEvents; repairedTbl(end, :)];
        repairedTbl(end, :) = [];
    end

    % --- Pair ON and OFF events, checking duration ---
    onIdx  = find(repairedTbl.type == string(onLabel));
    offIdx = find(repairedTbl.type == string(offLabel));

    validPairs = false(height(repairedTbl),1); % mask for rows to keep

    usedOffMask = false(size(offIdx)); % track used offs relative to offIdx list

    % Map local indices: offIdx(k) corresponds to repairedTbl row offIdx(k)
    for k = 1:length(onIdx)
        thisOnIdx = onIdx(k);

        % find the first OFF index that is greater than thisOnIdx
        candidateOffs = offIdx(offIdx > thisOnIdx & ~usedOffMask);
        if isempty(candidateOffs)
            continue; % no off after this on
        end
        thisOffIdx = candidateOffs(1);

        % compute duration (samples)
        dur = repairedTbl.sample(thisOffIdx) - repairedTbl.sample(thisOnIdx);

        if dur >= durationRange(1) && dur <= durationRange(2)
            % mark these two rows as valid
            validPairs(thisOnIdx) = true;
            validPairs(thisOffIdx) = true;
            % mark this off as used in the offIdx indexing
            usedOffMask(offIdx == thisOffIdx) = true;
        else
            % If duration invalid, keep them as removed
            % (we'll append them to removedEvents later)
            continue;
        end
    end

    % Rows not marked valid are removed
    removedEvents = [removedEvents; repairedTbl(~validPairs, :)];

    % Build final clean table
    cleanTable = repairedTbl(validPairs, :);

    % Ensure final alternation (should be ON,OFF,ON,OFF... starting with ON)
    if ~isempty(cleanTable)
        typesFinal = cleanTable.type;
        for i = 2:height(cleanTable)
            if typesFinal(i) == typesFinal(i-1)
                % if problem persists, remove the offending row and log it
                removedEvents = [removedEvents; cleanTable(i, :)];
                cleanTable(i, :) = [];
            end
        end
    end

    % Sort removedEvents by sample for convenience
    if ~isempty(removedEvents)
        removedEvents = sortrows(removedEvents, 'sample');
    end

    % Final log
    fprintf('cleanAndRepairTTL: kept %d events (%d pairs). Removed %d events.\n', ...
        height(cleanTable), height(cleanTable)/2, height(removedEvents));
end
