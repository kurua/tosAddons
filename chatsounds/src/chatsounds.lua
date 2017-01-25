--dofile("../data/addon_d/chatsounds/chatsounds.lua");

local addonName = "CHATSOUNDS";
local addonNameLower = string.lower(addonName);

local author = "kurua";

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {};
local g = _G['ADDONS'][author][addonName];

g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower);
g._version = "v0.2.2";

if not g.loaded then
  g.settings = {
    enable = true,
    notice = {
      party = false,
      guild = false,
      wis = true
    }
  };
end

CHAT_SYSTEM(string.format("[%s] %s loaded.", addonNameLower, g._version));

function CHATSOUNDS_ON_INIT(addon, frame)

  g.addon = addon;
  g.frame = frame;

  local acutil = require('acutil');

  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      CHAT_SYSTEM(string.format("[%s] Can't load setting files.", addonNameLower));
    else
      g.settings = t;
    end
    acutil.saveJSON(g.settingsFileLoc, g.settings);
    acutil.slashCommand("/"..addonNameLower, CHATSOUNDS_PROCESS_COMMAND);
    addon:RegisterMsg("GAME_START_3SEC", "CHATSOUNDS_ON_GAME_START_DELAY");
    CHATSOUNDS_SHOW_STATUS();
    g.loaded = true;
  end

end
--==============================
-- 遅延処理
--==============================
function CHATSOUNDS_ON_GAME_START_DELAY(frame)
  local acutil = require('acutil');
  acutil.setupEvent(g.addon, "DRAW_CHAT_MSG", "CHATSOUNDS_DRAW_CHAT_MSG_EVENT");
end

--==============================
-- 設定表示
--==============================
function CHATSOUNDS_SHOW_STATUS()
  local tmpMsg;
  if g.settings.notice.party == true then
    tmpMsg = "[ChatSounds]P: ○ /";
  else
    tmpMsg = "[ChatSounds]P: × /";
  end

  if g.settings.notice.guild == true then
    tmpMsg = tmpMsg .. "　G: ○ /";
  else
    tmpMsg = tmpMsg .. "　G: × /";
  end

  if g.settings.notice.wis == true then
    tmpMsg = tmpMsg .. "　W: ○";
  else
    tmpMsg = tmpMsg .. "　W: ×";
  end
  CHAT_SYSTEM(tmpMsg);
end

--==============================
-- コマンド処理
--==============================
function CHATSOUNDS_PROCESS_COMMAND(command)
  local acutil = require('acutil');

  local cmd = "";
  local action = "";

  if #command == 2 then
    cmd = table.remove(command, 1);
    action = table.remove(command, 1);

    if cmd == "p" then
      if action == "on" then
        g.settings.notice.party = true;
      elseif action == "off" then
        g.settings.notice.party = false;
      else
        return;
      end

    elseif cmd == "g" then
      if action == "on" then
        g.settings.notice.guild = true;
      elseif action == "off" then
        g.settings.notice.guild = false;
      else
        return;
      end
    elseif cmd == "w" then
      if action == "on" then
        g.settings.notice.wis = true;
      elseif action == "off" then
        g.settings.notice.wis = false;
      else
        return;
      end
      return;
    end
    CHATSOUNDS_SHOW_STATUS();
    acutil.saveJSON(g.settingsFileLoc, g.settings);
  end
end

--==============================
-- メイン処理
--==============================
function CHATSOUNDS_DRAW_CHAT_MSG_EVENT(frame, msg)

  local acutil = require('acutil');
  local groupboxname, size, startindex, framename = acutil.getEventArgs(msg);

  if startindex < 0 then
    return;
  end

  if framename == nil then
    framename = "chatframe";
  end

  local mainchatFrame = ui.GetFrame("chatframe")
  local chatframe = ui.GetFrame(framename)
  if chatframe == nil then
    return;
  end

  local groupbox = GET_CHILD(chatframe,groupboxname);
  if groupbox == nil then
    --ここは中は未検証
    local gboxleftmargin = chatframe:GetUserConfig("GBOX_LEFT_MARGIN")
    local gboxrightmargin = chatframe:GetUserConfig("GBOX_RIGHT_MARGIN")
    local gboxtopmargin = chatframe:GetUserConfig("GBOX_TOP_MARGIN")
    local gboxbottommargin = chatframe:GetUserConfig("GBOX_BOTTOM_MARGIN")

    groupbox = chatframe:CreateControl("groupbox", groupboxname, chatframe:GetWidth() - (gboxleftmargin + gboxrightmargin), chatframe:GetHeight() - (gboxtopmargin + gboxbottommargin), ui.RIGHT, ui.BOTTOM, 0, 0, gboxrightmargin, gboxbottommargin);
  end

  if startindex == 0 then
    return;
  end

  local clusterinfo = session.ui.GetChatMsgClusterInfo(groupboxname, startindex)
  if clusterinfo == nil then
    return;
  end
  local clustername = "cluster_"..clusterinfo:GetClusterID();
  local msgType = clusterinfo:GetMsgType();

  if ((( groupbox:GetName() == "chatgbox_4" and ui.IsMyChatCluster(clusterinfo) == false ) and msgType == "Party" ) and g.settings.notice.party == true ) then
    imcSound.PlaySoundEvent('button_click_stats_up');

  elseif ((( groupbox:GetName() == "chatgbox_8" and ui.IsMyChatCluster(clusterinfo) == false ) and msgType == "Guild") and g.settings.notice.guild == true ) then
    imcSound.PlaySoundEvent('button_click_stats_up');

  elseif ((( groupbox:GetName() == "chatgbox_"..msgType ) and ui.IsMyChatCluster(clusterinfo) == false ) and g.settings.notice.wis == true ) then
    imcSound.PlaySoundEvent('button_click_stats_up');
  end

end
