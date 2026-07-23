local utils = require 'mp.utils'
local msg = require 'mp.msg'

local SLOT_DURATION   = 0.01
local WINDOW_DURATION = 0.5

local buckets_v = {}
local buckets_a = {}
local data_ready = false
local is_network = false

local function format_bps(bps)
    if bps == 0 then return "-" end
    return string.format("%10s", string.format("%.0f kbps", bps / 1000))
end

local function shell_escape(s)
    if not s then return "''" end
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function get_absolute_path(path)
    if not path then return nil end
    if path:match("^%a+://") or path:match("^/") then
        return path
    end
    local pwd = mp.get_property("working-directory")
    if pwd then
        return utils.join_path(pwd, path)
    end
    return path
end

mp.set_property("user-data/real-v-bitrate", mp.get_property_osd("video-bitrate") or "-")
mp.set_property("user-data/real-a-bitrate", mp.get_property_osd("audio-bitrate") or "-")

local function parse_file(filepath, label)
    local buckets = {}
    local f = io.open(filepath, "r")
    if not f then 
        msg.error(string.format("[%s] Cannot open temp file: %s", label, filepath))
        return buckets 
    end
    
    local count = 0
    for line in f:lines() do
        local pts_str, size_str = line:match("^([^,]+),([0-9]+)")
        if pts_str and size_str then
            local p = tonumber(pts_str)
            local sz = tonumber(size_str)
            if p and sz then
                local b_idx = math.floor(p / SLOT_DURATION)
                buckets[b_idx] = (buckets[b_idx] or 0) + sz
                count = count + 1
            end
        end
    end
    f:close()
    os.remove(filepath)
    
    msg.info(string.format("[%s] Parse success: Calculated %d packets", label, count))
    return buckets
end

mp.register_event("file-loaded", function()
    buckets_v = {}
    buckets_a = {}
    data_ready = false
    is_network = false

    local path = mp.get_property("path")
    if not path then return end

    local info = utils.file_info(path)
    if not info or not info.is_file then
        is_network = true
        return
    end

    local abs_path = get_absolute_path(path)
    local pid = mp.get_property("pid") or "default"
    
    local function run_probe(stream_type, label)
        local safe_type = stream_type:gsub(":", "_")
        local tmp_file = string.format("/tmp/mpv_probe_%s_%s.txt", pid, safe_type)
        
        local cmd = string.format(
            'ffprobe -v error -select_streams %s -show_entries packet=pts_time,size -of csv=p=0 %s > %s',
            shell_escape(stream_type),
            shell_escape(abs_path),
            shell_escape(tmp_file)
        )
        
        msg.info(string.format("[%s] Analyzing ...", label))
        
        mp.command_native_async({
            name = "subprocess",
            args = { "sh", "-c", cmd },
            capture_stdout = false,
            capture_stderr = true
        }, function(success, res, err)
            if not success then
                msg.error(string.format("[%s] Internal process error: %s", label, tostring(err or "unknown")))
                os.remove(tmp_file)
                return
            end
            
            if res.status ~= 0 then
                msg.error(string.format("[%s] ffprobe failed: status %d", label, res.status))
                os.remove(tmp_file)
            else
                if stream_type == "v:0" then
                    buckets_v = parse_file(tmp_file, label)
                else
                    buckets_a = parse_file(tmp_file, label)
                end
                if (next(buckets_v) ~= nil) or (next(buckets_a) ~= nil) then
                    data_ready = true
                end
            end
        end)
    end

    run_probe("v:0", "Video")
    run_probe("a:0", "Audio")
end)

local function update_bitrate()
    if is_network or not data_ready then
        mp.set_property("user-data/real-v-bitrate", mp.get_property_osd("video-bitrate") or "-")
        mp.set_property("user-data/real-a-bitrate", mp.get_property_osd("audio-bitrate") or "-")
        return
    end

    local pos = mp.get_property_number("time-pos")
    if not pos then return end

    local current_slot = math.floor(pos / SLOT_DURATION)
    local slots_in_window = math.max(1, math.floor(WINDOW_DURATION / SLOT_DURATION))
    
    local v_total = 0
    local a_total = 0

    for i = current_slot - slots_in_window + 1, current_slot do
        v_total = v_total + (buckets_v[i] or 0)
        a_total = a_total + (buckets_a[i] or 0)
    end

    local v_bps = (v_total * 8) / WINDOW_DURATION
    local a_bps = (a_total * 8) / WINDOW_DURATION

    mp.set_property("user-data/real-v-bitrate", format_bps(v_bps))
    mp.set_property("user-data/real-a-bitrate", format_bps(a_bps))
end

mp.observe_property("time-pos", "number", update_bitrate)
